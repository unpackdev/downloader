// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface MintableCollection is IERC721 {
    function burn(uint256 tokenId) external;
    function mint(address to, uint256 tokenId) external;
}