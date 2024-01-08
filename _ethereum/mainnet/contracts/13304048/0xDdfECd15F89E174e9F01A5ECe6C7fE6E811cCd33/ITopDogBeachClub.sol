// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

interface ITopDogBeachClub is IERC721Enumerable {
    function getBirthday(uint256 tokenId) external view returns (uint256);
}