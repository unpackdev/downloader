// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ISwapRouter.sol";
import "./IPeripheryPayments.sol";

interface IUniswapRouter is ISwapRouter, IPeripheryPayments {}
