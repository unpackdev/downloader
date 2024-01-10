// SPDX-License-Identifier: GPL-3.0

/// @title Interface for OrbitsNFT

pragma solidity ^0.8.6;

import "./IERC721.sol";

interface IOrbitsNFT is IERC721 {

    function mint(string calldata) external returns (uint256);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function lockMinter() external;
}
