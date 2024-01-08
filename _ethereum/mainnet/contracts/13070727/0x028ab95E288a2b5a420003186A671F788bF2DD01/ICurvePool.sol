// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface ICurvePool {
    function get_dy_underlying(int128, int128, uint256) external view returns (uint256);
    function exchange_underlying(int128, int128, uint256, uint256) external returns (uint256);
    function remove_liquidity_one_coin(address, uint256, int128, uint256) external;
}
