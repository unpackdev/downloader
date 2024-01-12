pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./IERC721.sol";

interface IBurnableERC721 is IERC721 {
    function burn(uint256 tokenId) external;
}