// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IAtomicPriceAggregator.sol";
import "./IUniswapV3PositionInfoProvider.sol";

interface IUniswapV3OracleWrapper is
    IAtomicPriceAggregator,
    IUniswapV3PositionInfoProvider
{}
