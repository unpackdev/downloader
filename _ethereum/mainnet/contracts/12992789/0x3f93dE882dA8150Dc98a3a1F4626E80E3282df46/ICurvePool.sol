// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

interface ICurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
    function base_coins(uint256) external view returns (address);
}