// SPDX-License-Identifier: GPL-3.0

/// @title Earth FM auction house

/******************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
 * ░░░░░░░░░░░░░░,@@@@@@@,░░░░░░░░░░░░░░░░*
 * ░░░░░,,,..░░░,@@@@@@/@@,░░.oo8888o.░░░░*
 * ░░░,&%%&%&&%,@@@@@/@@@@@@,8888\88/8o░░░*
 * ░░,%&\%&&%&&%,@@@\@@@/@@@88\88888/88'░░*
 * ░░%&&%&%&/%&&%@@\@@/ /@@@88888\88888'░░*
 * ░░%&&%/ %&%%&&@@\ V /@@'░`88\8 `/88'░░░*
 * ░░░&%\ ` /%&░░░░░|.|░░░░░░░░\ '|8'░░░░░*
 * ░░░░░░|o|░░░░░░░░| |░░░░░░░░░| |░░░░░░░*
 * ░░░░░░|.|░░░░░░░░| |░░░░░░░░░| |░░░░░░░*
 * ░░░\\/ ._\//_/__/  ,\_//__\\/.  \_//░░░*
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
 *****************************************/

// LICENSE
// EarthFMAuctionHouse.sol is a modified version of Nouns DAO auction house.sol:
// https://raw.githubusercontent.com/nounsDAO/nouns-monorepo/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol

pragma solidity ^0.8.6;

import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IEarthFMAuctionHouse } from './interfaces/IEarthFMAuctionHouse.sol';
import { IEarthFM } from './interfaces/IEarthFM.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract EarthFMAuctionHouse is IEarthFMAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The EarthFM ERC1155 token contract
    IEarthFM public earthFm;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    IEarthFMAuctionHouse.Auction public auction;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        IEarthFM _earthFm,
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        earthFm = _earthFm;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction, mint a new EarthFm sound, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a EarthSound, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 soundId) external payable override nonReentrant {
        IEarthFMAuctionHouse.Auction memory _auction = auction;

        require(_auction.earthSoundId == soundId, 'Earth Sound not up for auction');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.earthSoundId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.earthSoundId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Nouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Nouns auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try earthFm.mint() returns (uint256 earthSoundId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                earthSoundId: earthSoundId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(earthSoundId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction() internal {
        IEarthFMAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            //earthFm.burn(_auction.earthSoundId);
        } else {
            earthFm.safeTransferFrom(address(this), _auction.bidder, _auction.earthSoundId, 1,"");
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(_auction.earthSoundId, _auction.bidder, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}