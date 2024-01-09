// SPDX-License-Identifier: GPL-3.0

/// @title Interface for SunriseToken

pragma solidity ^0.8.6;

import "./IERC721.sol";

interface ISunriseToken is IERC721 {
    event SunriseCreated(uint256 indexed tokenId);

    event SunriseBurned(uint256 indexed tokenId);

    event SunriseArtClubUpdated(address sunriseArtClub);

    event MinterUpdated(address minter);

    event MinterLocked();

    function getMaxSupply() external view returns (uint256);

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function setSunriseArtClub(address sunriseArtClub) external;

    function setMinter(address minter) external;

    function lockMinter() external;
}
