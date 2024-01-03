// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwap3 {
    /*
    @dev Returns price of 1 Curve LP token in USD
    */
    function get_virtual_price() external view returns (uint);

    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint token_amount,
        int128 i,
        uint min_uamount
    ) external;

    function balances(uint index) external view returns (uint);
}
