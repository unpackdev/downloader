// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ICurvePool2 { 
    function add_liquidity(uint256[4] memory, uint256) external;
    function remove_liquidity_one_coin(uint256, int128, uint256) external;
    function remove_liquidity_imbalance(uint256[4] memory, uint256) external;
    function get_virtual_price() external returns (uint256);
    function calc_token_amount(uint256[4] memory, bool) external returns(uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}