// SPDX-License-Identifier: GPL-3.0

/// @title Interface for EarthFM NFT

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

import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

interface IEarthFM is IERC1155 {

    event EarthSoundMinted(uint256 indexed tokenId);

    event EarthSoundBurned(uint256 indexed tokenId);

    event DAOAddressUpdated(address daoAddress);

    event MinterUpdated(address minter);

    event MinterLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setDAOAddress(address daoAddress) external;

    function setMinter(address minter) external;

    function lockMinter() external;
}