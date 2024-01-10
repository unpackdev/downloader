// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Math.sol";
import "./SafeCast.sol";
import "./FeedRegistryInterface.sol";
import "./IPriceProvider.sol";
import "./IERC20Metadata.sol";
import "./Governable.sol";

/**
 * @title ChainLink's price provider
 * @dev This contract wraps chainlink price feed
 */
contract ChainlinkPriceProvider is IPriceProvider, Governable {
    // chainlink follows https://en.wikipedia.org/wiki/ISO_4217
    address public constant USD = address(840);
    FeedRegistryInterface public immutable priceFeed;
    address public immutable weth;
    address public immutable wbtc;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    // For multi chain support take all input in constructor instead of defining constant
    constructor(
        FeedRegistryInterface _priceFeed,
        address _weth,
        address _wbtc
    ) {
        require(address(_priceFeed) != address(0), "zero-feed-address");
        require(address(_weth) != address(0), "zero-weth-address");
        require(address(_wbtc) != address(0), "zero-wbtc-address");
        priceFeed = _priceFeed;
        weth = _weth;
        wbtc = _wbtc;
    }

    /// @inheritdoc IPriceProvider
    function quote(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        (uint256 _amountInUsd, uint256 _lastUpdatedAt0) = quoteTokenToUsd(_assetIn, _amountIn);
        (_amountOut, _lastUpdatedAt) = quoteUsdToToken(_assetOut, _amountInUsd);
        _lastUpdatedAt = Math.min(_lastUpdatedAt0, _lastUpdatedAt);
    }

    /// @inheritdoc IPriceProvider
    function quoteTokenToUsd(address _token, uint256 _amount)
        public
        view
        returns (uint256 _amountInUsd, uint256 _lastUpdatedAt)
    {
        uint256 _price;
        (_price, _lastUpdatedAt) = _getPriceOfAsset(_token);
        _amountInUsd = (_amount * _price) / 10**IERC20Metadata(_token).decimals();
    }

    /// @inheritdoc IPriceProvider
    function quoteUsdToToken(address _token, uint256 _amountInUsd)
        public
        view
        returns (uint256 _amount, uint256 _lastUpdatedAt)
    {
        uint256 _price;
        (_price, _lastUpdatedAt) = _getPriceOfAsset(_token);
        _amount = (_amountInUsd * 10**IERC20Metadata(_token).decimals()) / _price;
    }

    function _getPriceOfAsset(address _token) private view returns (uint256, uint256) {
        // Chainlink price feed use ETH and BTC as token address
        if (_token == weth) {
            _token = ETH;
        } else if (_token == wbtc) {
            _token = BTC;
        }
        (, int256 _price, , uint256 _lastUpdatedAt, ) = priceFeed.latestRoundData(_token, USD);
        return (SafeCast.toUint256(_price), _lastUpdatedAt);
    }
}
