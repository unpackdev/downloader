// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

abstract contract IZkSwap {
    function createPair(address _tokenA, address _tokenB) external virtual;

    function createETHPair(address _tokenERC20) external virtual;
}
