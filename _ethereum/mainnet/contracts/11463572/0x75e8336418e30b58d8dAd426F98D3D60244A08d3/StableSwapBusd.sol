// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface StableSwapBusd {
    function get_virtual_price() external view returns (uint);

    /*
    0 DAI
    1 USDC
    2 USDT
    3 BUSD
    */
    function balances(int128 index) external view returns (uint);
}
