// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface DepositPax {
    /*
    0 DAI
    1 USDC
    2 USDT
    3 PAX
    */
    function add_liquidity(uint[4] memory amounts, uint min) external;

    function remove_liquidity_one_coin(
        uint amount,
        int128 index,
        uint min,
        bool donateDust
    ) external;
}
