// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IRouterComponent.sol";

import "./SwapTask.sol";
import "./SwapQuote.sol";

interface ISwapper is IRouterComponent {
    function getBestDirectPairSwap(SwapTask memory swapTask, address adapter)
        external
        returns (SwapQuote memory quote);
}
