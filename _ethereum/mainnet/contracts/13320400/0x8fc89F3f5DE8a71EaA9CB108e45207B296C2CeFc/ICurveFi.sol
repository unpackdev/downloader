// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICurveFi {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable returns(uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns(uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns(uint256);
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns(uint256);
    function get_virtual_price() external returns (uint256);
}