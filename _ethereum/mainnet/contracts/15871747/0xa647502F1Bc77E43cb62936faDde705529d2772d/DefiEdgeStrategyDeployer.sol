// SPDX-License-Identifier: BSL

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./DefiEdgeStrategy.sol";
import "./IStrategyBase.sol";
import "./IDefiEdgeStrategyDeployer.sol";

/**
 * @title DefiEdge Strategy Deployer
 * @notice The contract seperately deploys the strategy contracts and factory connects it with manager
 */

contract DefiEdgeStrategyDeployer is IDefiEdgeStrategyDeployer {
    function createStrategy(
        IStrategyFactory _factory,
        IUniswapV3Pool _pool,
        IOneInchRouter _swapRouter,
        FeedRegistryInterface _chainlinkRegistry,
        IStrategyManager _manager,
        bool[2] memory _usdAsBase,
        IStrategyBase.Tick[] memory _ticks
    ) external override returns (address strategy) {
        strategy = address(new DefiEdgeStrategy(_factory, _pool, _swapRouter, _chainlinkRegistry, _manager, _usdAsBase, _ticks));

        emit StrategyDeployed(address(strategy));
    }
}
