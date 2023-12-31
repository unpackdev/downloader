// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";

import "./DittoPoolMain.sol";
import "./DittoPoolMarketMake.sol";
import "./DittoPoolTrade.sol";

/**
 * @title DittoPool
 * @notice DittoPool AMM shared liquidity trading pools. See DittoPoolMain, MarketMake and Trade for implementation.
 */
abstract contract DittoPool is IDittoPool, DittoPoolMain, DittoPoolMarketMake, DittoPoolTrade { }
