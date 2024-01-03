// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface DepositGusd {
    /*
    0 GUSD
    1 DAI
    2 USDC
    3 USDT
    */
    function add_liquidity(uint[4] memory amounts, uint min) external returns (uint);

    function remove_liquidity_one_coin(
        uint amount,
        int128 index,
        uint min
    ) external returns (uint);
}
