// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721.sol";

interface IPolys is IERC721 {
    function tokenNameOf(uint polyId) external view returns (string memory);
    function parentsOfMix(uint256 mixId) external view returns (uint256, uint256);
}