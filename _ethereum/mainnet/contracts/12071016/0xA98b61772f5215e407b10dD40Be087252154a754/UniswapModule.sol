// SPDX-License-Identifier: None
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IUniswapModule.sol";

/// @title Slingshot Uniswap Module
contract UniswapModule is IUniswapModule {
    function getRouter() override public pure returns (address) {
        return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }
}
