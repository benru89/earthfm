// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Earth FM Auction House

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

pragma solidity ^0.8.6;

interface IEarthFMAuctionHouse {
    struct Auction {
        // ID for the Earth sound (ERC1155 token ID)
        uint256 earthSoundId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed earthSoundId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed earthSoundId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed earthSoundId, uint256 endTime);

    event AuctionSettled(uint256 indexed earthSoundId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event ErrorLogging(string reason);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 earthSoundId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}