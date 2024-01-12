// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Math.sol";
import "./IPriceProvidersAggregator.sol";
import "./Governable.sol";

/**
 * @title Price Providers Aggregator
 */
contract PriceProvidersAggregator is IPriceProvidersAggregator, Governable {
    /**
     * The native token (usually the most liquid asset in the chain)
     * @dev Is used when getting quote from two price providers
     */
    address public immutable nativeToken;

    /**
     * @notice Price providers map
     */
    mapping(DataTypes.Provider => IPriceProvider) public override priceProviders;

    /// Emitted when an price provider is updated
    event PriceProviderUpdated(
        DataTypes.Provider provider,
        IPriceProvider oldPriceProvider,
        IPriceProvider newPriceProvider
    );

    constructor(address nativeToken_) {
        require(nativeToken_ != address(0), "native-token-is-null");
        nativeToken = nativeToken_;
    }

    /// @inheritdoc IPriceProvidersAggregator
    function getPriceInUsd(DataTypes.Provider provider_, address token_)
        external
        view
        override
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.getPriceInUsd(token_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quote(
        DataTypes.Provider provider_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.quote(tokenIn_, tokenOut_, amountIn_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quote(
        DataTypes.Provider providerIn_,
        address tokenIn_,
        DataTypes.Provider providerOut_,
        address tokenOut_,
        uint256 amountIn_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        IPriceProvider _providerIn = priceProviders[providerIn_];
        require(address(_providerIn) != address(0), "provider-in-not-set");

        if (providerIn_ == providerOut_) {
            return _providerIn.quote(tokenIn_, tokenOut_, amountIn_);
        }

        IPriceProvider _providerOut = priceProviders[providerOut_];
        require(address(_providerOut) != address(0), "provider-out-not-set");

        (_amountOut, _lastUpdatedAt) = _providerIn.quote(tokenIn_, nativeToken, amountIn_);
        uint256 __lastUpdatedAt;
        (_amountOut, __lastUpdatedAt) = _providerOut.quote(nativeToken, tokenOut_, _amountOut);
        _lastUpdatedAt = Math.min(__lastUpdatedAt, _lastUpdatedAt);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quoteTokenToUsd(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view override returns (uint256 amountOut_, uint256 _lastUpdatedAt) {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.quoteTokenToUsd(token_, amountIn_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function quoteUsdToToken(
        DataTypes.Provider provider_,
        address token_,
        uint256 amountIn_
    ) external view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        IPriceProvider _provider = priceProviders[provider_];
        require(address(_provider) != address(0), "provider-not-set");
        return _provider.quoteUsdToToken(token_, amountIn_);
    }

    /// @inheritdoc IPriceProvidersAggregator
    function setPriceProvider(DataTypes.Provider provider_, IPriceProvider priceProvider_)
        external
        override
        onlyGovernor
    {
        require(provider_ != DataTypes.Provider.NONE, "invalid-provider");
        IPriceProvider _current = priceProviders[provider_];
        require(priceProvider_ != _current, "same-as-current");

        emit PriceProviderUpdated(provider_, _current, priceProvider_);

        priceProviders[provider_] = priceProvider_;
    }
}
