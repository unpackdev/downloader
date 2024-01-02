// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "./IV2SwapRouter.sol";
import "./IV3SwapRouter.sol";
import "./IMulticallExtended.sol";

/// @title Router token swapping functionality
interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter, IMulticallExtended {

}
