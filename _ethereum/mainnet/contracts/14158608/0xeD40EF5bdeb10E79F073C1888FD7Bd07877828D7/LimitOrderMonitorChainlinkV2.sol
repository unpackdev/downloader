// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

import "./KeeperRegistryInterface.sol";
import "./AggregatorV3Interface.sol";

import "./LimitOrderMonitor.sol";

/// @title  LimitOrderMonitorChainlink
contract LimitOrderMonitorChainlinkV2 is LimitOrderMonitor {

    /// @dev fast gas
    AggregatorV3Interface public FAST_GAS_FEED;

    function initialize(IOrderManager _orderManager,
        IUniswapV3Factory _factory,
        IERC20 _KROM,
        address _keeper,
        uint256 _batchSize,
        uint256 _monitorSize,
        uint256 _upkeepInterval,
        AggregatorV3Interface fastGasFeed) public initializer {

        super.initialize(
            _orderManager, _factory, _KROM, _keeper,
                _batchSize, _monitorSize, _upkeepInterval
        );

        FAST_GAS_FEED = fastGasFeed;
    }

    function _getGasPrice(uint256 _txnGasPrice) internal view virtual override
    returns (uint256 gasPrice) {

        if (_txnGasPrice > 0) {
            return _txnGasPrice;
        }

        uint256 timestamp;
        int256 feedValue;
        (,feedValue,,timestamp,) = FAST_GAS_FEED.latestRoundData();
        gasPrice = uint256(feedValue);
    }
}