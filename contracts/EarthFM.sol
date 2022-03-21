// SPDX-License-Identifier: GPL-3.0

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
pragma solidity ^0.8.1;


import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import { IEarthFM } from './interfaces/IEarthFM.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';


contract EarthFM is IEarthFM, ERC1155, Ownable{

    //OpenSea expects a public property name
    string public name = "Earth.fm";

    // An address who has permissions to mint
    address public minter;

     // The dao address
    address public daoAddress;

    // The internal asset ID tracker
    uint256 private _currentEarthSoundId;

    // The internal season tracked
    uint256 private _currentEarthSoundSeasonId;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // MODIFIERS

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    /**
     * @notice Require that the sender is the DAO address.
     */
    modifier onlyDAOAddress() {
        require(msg.sender == daoAddress, 'Sender is not the DAO address');
        _;
    }

    constructor(
        address _daoAddress,
        address _minter
    ) ERC1155("ipfs://QmRKRiJK6W2WkWRRLMZsUr2iFDxnupR5VNpxjyHeRcfxm7/{id}.json") {
        daoAddress = _daoAddress;
        minter = _minter;
    }

    /**
     * @notice Mint 1 Earth Sound to the minter
     */
    function mint() public override onlyMinter returns (uint256) {
        _mint(minter, ++_currentEarthSoundId, 1, "");

        emit EarthSoundMinted(_currentEarthSoundId);
        return _currentEarthSoundId;
    }

    /**
     * @notice Burn an Earth Sound.
     */
    function burn(uint256 earthSoundId) public override onlyMinter {
        _burn(minter, 1, earthSoundId);
        emit EarthSoundBurned(earthSoundId);
    }


    /**
     * @notice Set the DAO Address.
     * @dev Only callable by the DAO address when not locked.
     */
    function setDAOAddress(address _daoAddress) external override onlyDAOAddress {
        daoAddress = _daoAddress;

        emit DAOAddressUpdated(_daoAddress);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }


}
