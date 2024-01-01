// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICurve {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable returns (uint256);

    function lp_token() external view returns (address);

    function calc_token_amount(
        uint256[2] calldata amounts,
        bool is_deposit
    ) external view returns (uint256);
}