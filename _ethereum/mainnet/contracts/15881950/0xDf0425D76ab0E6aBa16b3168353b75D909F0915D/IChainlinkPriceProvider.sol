// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "./IPriceProvider.sol";

interface IChainlinkPriceProvider is IPriceProvider {
    /**
     * @notice Update token's aggregator
     */
    function updateAggregator(address token_, AggregatorV3Interface aggregator_) external;
}
