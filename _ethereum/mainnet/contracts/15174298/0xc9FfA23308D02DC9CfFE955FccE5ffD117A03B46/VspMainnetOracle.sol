// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Math.sol";
import "./UsingProvidersAggregator.sol";
import "./UsingMaxDeviation.sol";
import "./UsingStableCoinProvider.sol";
import "./UsingStalePeriod.sol";
import "./IVspOracle.sol";
import "./IUniswapV2LikePriceProvider.sol";

/**
 * @title Main oracle
 * @dev Reuses `PriceProvidersAggregator` and add support to USD quotes
 */
contract VspMainnetOracle is
    IVspOracle,
    UsingProvidersAggregator,
    UsingMaxDeviation,
    UsingStableCoinProvider,
    UsingStalePeriod
{
    uint256 public constant ONE_VSP = 1e18;
    address public constant VSP_ADDRESS = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        IPriceProvidersAggregator providersAggregator_,
        IStableCoinProvider stableCoinProvider_,
        uint256 maxDeviation_,
        uint256 stalePeriod_
    )
        UsingProvidersAggregator(providersAggregator_)
        UsingStableCoinProvider(stableCoinProvider_)
        UsingMaxDeviation(maxDeviation_)
        UsingStalePeriod(stalePeriod_)
    {
        require(address(stableCoinProvider_) != address(0), "stable-coin-provider-is-null");
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address _asset) external view returns (uint256 _priceInUsd) {
        require(address(_asset) == VSP_ADDRESS, "invalid-token");
        uint256 _lastUpdatedAt;
        IPriceProvidersAggregator _aggregator = providersAggregator;

        (_priceInUsd, _lastUpdatedAt) = _aggregator.quoteTokenToUsd(
            DataTypes.Provider.UNISWAP_V2,
            VSP_ADDRESS,
            ONE_VSP
        );
        (uint256 _priceInUsd1, uint256 _lastUpdatedAt1) = _aggregator.quoteTokenToUsd(
            DataTypes.Provider.SUSHISWAP,
            VSP_ADDRESS,
            ONE_VSP
        );

        require(
            _priceInUsd > 0 && _priceInUsd1 > 0 && !_priceIsStale(Math.min(_lastUpdatedAt, _lastUpdatedAt1)),
            "one-or-both-prices-invalid"
        );
        require(_isDeviationOK(_priceInUsd, _priceInUsd1), "prices-deviation-too-high");
        _lastUpdatedAt = Math.min(_lastUpdatedAt, _lastUpdatedAt1);
    }

    /// @inheritdoc IVspOracle
    function update() external {
        IPriceProvidersAggregator _aggregator = providersAggregator;
        address _stableCoin = stableCoinProvider.getStableCoinIfPegged();

        IUniswapV2LikePriceProvider _uniswapV2PriceProvider = IUniswapV2LikePriceProvider(
            address(_aggregator.priceProviders(DataTypes.Provider.UNISWAP_V2))
        );
        IUniswapV2LikePriceProvider _sushiswapPriceProvider = IUniswapV2LikePriceProvider(
            address(_aggregator.priceProviders(DataTypes.Provider.SUSHISWAP))
        );

        _uniswapV2PriceProvider.updateOrAdd(VSP_ADDRESS, WETH_ADDRESS);
        _uniswapV2PriceProvider.updateOrAdd(WETH_ADDRESS, _stableCoin);
        _sushiswapPriceProvider.updateOrAdd(VSP_ADDRESS, WETH_ADDRESS);
        _sushiswapPriceProvider.updateOrAdd(WETH_ADDRESS, _stableCoin);
    }
}
