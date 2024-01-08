// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "IERC721.sol";

interface JackpotNFT is IERC721 {
    function exists(uint256 _tokenId) external view returns (bool);
    function goldenTicketsFound() external view returns (uint256);
}