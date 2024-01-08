// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface ITORContract is IERC721 {

    function burn(uint256 tokenId) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}