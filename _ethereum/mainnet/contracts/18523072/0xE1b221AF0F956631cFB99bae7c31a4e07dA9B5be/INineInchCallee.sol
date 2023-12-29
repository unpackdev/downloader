// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.19;

interface INineInchCallee {
    function nineInchCallee(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}
