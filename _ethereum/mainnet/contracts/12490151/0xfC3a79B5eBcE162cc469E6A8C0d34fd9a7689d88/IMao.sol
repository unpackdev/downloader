// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IMao is IERC721Enumerable {
    function getTokenEarnAmount(uint256 tokenId) external view returns (uint256);
}
