pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-3.0



interface ITacoswapV2Callee {
    function tacoswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
