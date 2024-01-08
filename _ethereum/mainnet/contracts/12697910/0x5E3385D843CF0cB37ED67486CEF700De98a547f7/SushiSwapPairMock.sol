// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./UniswapV2Pair.sol";

contract SushiSwapPairMock is UniswapV2Pair {
    constructor() public UniswapV2Pair() {}
}