// SPDX-License-Identifier: BSL

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./DefiEdgeTwapStrategy.sol";
import "./ITwapStrategyBase.sol";
import "./IDefiEdgeTwapStrategyDeployer.sol";

contract DefiEdgeTwapStrategyDeployer is IDefiEdgeTwapStrategyDeployer {
    function createStrategy(
        ITwapStrategyFactory _factory,
        IUniswapV3Pool _pool,
        IOneInchRouter _swapRouter,
        FeedRegistryInterface _chainlinkRegistry,
        ITwapStrategyManager _manager,
        bool[2] memory _useTwap,
        ITwapStrategyBase.Tick[] memory _ticks
    ) external override returns (address strategy) {
        strategy = address(new DefiEdgeTwapStrategy(_factory, _pool, _swapRouter, _chainlinkRegistry, _manager, _useTwap, _ticks));

        emit StrategyDeployed(address(strategy));
    }
}
