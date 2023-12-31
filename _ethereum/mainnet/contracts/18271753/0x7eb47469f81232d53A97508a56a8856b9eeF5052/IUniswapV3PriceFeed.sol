// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "./IAggregatorV3.sol";
import "./IUniswapV3Pool.sol";

/// @title IUniswapV3PriceFeed
/// @author Hifi
/// @notice Chainlink-compatible price feed for Uniswap V3 pools.
interface IUniswapV3PriceFeed is IAggregatorV3 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the quote asset is not in the pool.
    error IUniswapV3PriceFeed__QuoteAssetNotInPool(IErc20 quoteAsset);

    /// @notice Emitted when the TWAP criteria is not satisfied.
    error IUniswapV3PriceFeed__TwapCriteriaNotSatisfied();

    /// CONSTANT FUNCTIONS ///

    /// @notice The base asset for price calculations.
    function baseAsset() external view returns (IErc20);

    /// @notice The Uniswap V3 pool.
    function pool() external view returns (IUniswapV3Pool);

    /// @notice The quote asset for price calculations.
    function quoteAsset() external view returns (IErc20);

    /// @notice The time window for the TWAP calculation.
    function twapInterval() external view returns (uint32);
}
