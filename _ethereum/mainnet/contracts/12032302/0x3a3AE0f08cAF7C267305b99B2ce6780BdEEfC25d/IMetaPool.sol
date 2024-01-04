// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IMetaPool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
}