// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20Metadata.sol";
import "./Math.sol";
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./IUniswapV2Factory.sol";
import "./UsingStableCoinProvider.sol";
import "./IUniswapV2LikePriceProvider.sol";
import "./PriceProvider.sol";

/**
 * @title UniswapV2 (and forks) TWAP Oracle implementation
 * Based on https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
 */
contract UniswapV2LikePriceProvider is IUniswapV2LikePriceProvider, PriceProvider, UsingStableCoinProvider {
    using FixedPoint for *;

    /**
     * @notice The UniswapV2-like factory's address
     */
    address public immutable factory;

    /**
     * @notice The native wrapped token (e.g. WETH, WAVAX, WMATIC, etc)
     */
    address public immutable nativeToken;

    /// @inheritdoc IUniswapV2LikePriceProvider
    uint256 public override defaultTwapPeriod;

    struct Oracle {
        address token0;
        address token1;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    /**
     * @notice Oracles'
     * @dev pair => twapPeriod => oracle
     */
    mapping(IUniswapV2Pair => mapping(uint256 => Oracle)) public oracles;

    /// @notice Emitted when default TWAP period is updated
    event DefaultTwapPeriodUpdated(uint256 oldTwapPeriod, uint256 newTwapPeriod);

    constructor(
        address factory_,
        uint256 defaultTwapPeriod_,
        address nativeToken_,
        IStableCoinProvider stableCoinProvider_
    ) UsingStableCoinProvider(stableCoinProvider_) {
        require(factory_ != address(0), "factory-is-null");
        defaultTwapPeriod = defaultTwapPeriod_;
        factory = factory_;
        nativeToken = nativeToken_;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function hasOracle(IUniswapV2Pair pair_) external view override returns (bool) {
        return hasOracle(pair_, defaultTwapPeriod);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function hasOracle(IUniswapV2Pair pair_, uint256 twapPeriod_) public view override returns (bool) {
        return oracles[pair_][twapPeriod_].blockTimestampLast > 0;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function pairFor(address token0_, address token1_) public view override returns (IUniswapV2Pair _pair) {
        _pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(token0_, token1_));
    }

    /// @inheritdoc IPriceProvider
    function getPriceInUsd(address token_)
        public
        view
        override(IPriceProvider, PriceProvider)
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        return getPriceInUsd(token_, defaultTwapPeriod);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function getPriceInUsd(address token_, uint256 twapPeriod_)
        public
        view
        override
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt)
    {
        require(address(stableCoinProvider) != address(0), "stable-coin-not-supported");

        uint256 _stableCoinAmount;
        (_stableCoinAmount, _lastUpdatedAt) = quote(
            token_,
            stableCoinProvider.getStableCoinIfPegged(),
            twapPeriod_,
            10**IERC20Metadata(token_).decimals() // ONE
        );
        _priceInUsd = stableCoinProvider.toUsdRepresentation(_stableCoinAmount);
    }

    /// @inheritdoc IPriceProvider
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view override(IPriceProvider, PriceProvider) returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        return quote(tokenIn_, tokenOut_, defaultTwapPeriod, amountIn_);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function quote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        if (tokenIn_ == tokenOut_) {
            return (amountIn_, block.timestamp);
        }

        if (hasOracle(pairFor(tokenIn_, tokenOut_), twapPeriod_)) {
            (_amountOut, _lastUpdatedAt) = _getAmountOut(tokenIn_, tokenOut_, twapPeriod_, amountIn_);
        } else {
            (_amountOut, _lastUpdatedAt) = _getAmountOut(tokenIn_, nativeToken, twapPeriod_, amountIn_);
            uint256 __lastUpdatedAt;
            (_amountOut, __lastUpdatedAt) = _getAmountOut(nativeToken, tokenOut_, twapPeriod_, _amountOut);
            _lastUpdatedAt = Math.min(__lastUpdatedAt, _lastUpdatedAt);
        }
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function quoteTokenToUsd(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        uint256 _price;
        (_price, _lastUpdatedAt) = getPriceInUsd(token_, twapPeriod_);
        _amountOut = (amountIn_ * _price) / 10**IERC20Metadata(token_).decimals();
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function quoteUsdToToken(
        address token_,
        uint256 amountIn_,
        uint256 twapPeriod_
    ) public view override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        uint256 _price;
        (_price, _lastUpdatedAt) = getPriceInUsd(token_, twapPeriod_);
        _amountOut = (amountIn_ * 10**IERC20Metadata(token_).decimals()) / _price;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        return updateAndQuote(tokenIn_, tokenOut_, defaultTwapPeriod, amountIn_);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateAndQuote(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) public override returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        updateOrAdd(tokenIn_, tokenOut_, twapPeriod_);
        return quote(tokenIn_, tokenOut_, twapPeriod_, amountIn_);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateOrAdd(address tokenIn_, address tokenOut_) external override {
        updateOrAdd(tokenIn_, tokenOut_, defaultTwapPeriod);
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateOrAdd(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_
    ) public override {
        IUniswapV2Pair _pair = pairFor(tokenIn_, tokenOut_);
        if (!hasOracle(_pair, twapPeriod_)) {
            _addOracleFor(_pair, twapPeriod_);
        }
        _updateIfNeeded(_pair, twapPeriod_);
    }

    /**
     * @notice Create new oracle
     * @param pair_ The pair to get prices from
     * @param twapPeriod_ The TWAP period
     */
    function _addOracleFor(IUniswapV2Pair pair_, uint256 twapPeriod_) private {
        require(address(pair_) != address(0), "invalid-pair");

        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = pair_.getReserves();

        require(_reserve0 != 0 && _reserve1 != 0, "no-reserves");

        oracles[pair_][twapPeriod_] = Oracle({
            token0: pair_.token0(),
            token1: pair_.token1(),
            price0CumulativeLast: pair_.price0CumulativeLast(),
            price1CumulativeLast: pair_.price1CumulativeLast(),
            blockTimestampLast: _blockTimestampLast,
            price0Average: uint112(0).encode(),
            price1Average: uint112(0).encode()
        });
    }

    /**
     * @notice Get the output amount for a given oracle
     * @param tokenIn_ The address of assetIn
     * @param tokenOut_ The address of assetOut
     * @param twapPeriod_ The TWAP period
     * @param amountIn_ Amount of input token
     * @return _amountOut Amount out
     * @return _lastUpdatedAt Last updated timestamp
     */
    function _getAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 twapPeriod_,
        uint256 amountIn_
    ) private view returns (uint256 _amountOut, uint256 _lastUpdatedAt) {
        Oracle memory _oracle = oracles[pairFor(tokenIn_, tokenOut_)][twapPeriod_];
        if (tokenIn_ == _oracle.token0) {
            _amountOut = _oracle.price0Average.mul(amountIn_).decode144();
        } else {
            _amountOut = _oracle.price1Average.mul(amountIn_).decode144();
        }
        _lastUpdatedAt = _oracle.blockTimestampLast;
    }

    /**
     * @notice Update an oracle
     * @param pair_ The pair to update
     * @param twapPeriod_ The TWAP period
     * @return True if updated was performed
     */
    function _updateIfNeeded(IUniswapV2Pair pair_, uint256 twapPeriod_) private returns (bool) {
        Oracle storage _oracle = oracles[pair_][twapPeriod_];

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary
            .currentCumulativePrices(address(pair_));
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - _oracle.blockTimestampLast; // overflow is desired
        }
        // ensure that at least one full period has passed since the last update
        if (timeElapsed < twapPeriod_) return false;

        uint256 price0new;
        uint256 price1new;

        unchecked {
            price0new = price0Cumulative - _oracle.price0CumulativeLast;
            price1new = price1Cumulative - _oracle.price1CumulativeLast;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        _oracle.price0Average = FixedPoint.uq112x112(uint224(price0new / timeElapsed));
        _oracle.price1Average = FixedPoint.uq112x112(uint224(price1new / timeElapsed));
        _oracle.price0CumulativeLast = price0Cumulative;
        _oracle.price1CumulativeLast = price1Cumulative;
        _oracle.blockTimestampLast = blockTimestamp;
        return true;
    }

    /// @inheritdoc IUniswapV2LikePriceProvider
    function updateDefaultTwapPeriod(uint256 newDefaultTwapPeriod_) external override onlyGovernor {
        emit DefaultTwapPeriodUpdated(defaultTwapPeriod, newDefaultTwapPeriod_);
        defaultTwapPeriod = newDefaultTwapPeriod_;
    }
}
