// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./UniswapV2Factory.sol";

contract SushiSwapFactoryMock is UniswapV2Factory {
    constructor(address _feeToSetter) public UniswapV2Factory(_feeToSetter) {}
}