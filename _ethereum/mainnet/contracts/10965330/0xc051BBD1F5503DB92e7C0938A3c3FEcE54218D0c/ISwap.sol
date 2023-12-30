// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface ISwap {
    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}
