// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "./ILiquidationPriceOracleBase.sol";
import "./IChainLinkAggregatorProxy.sol";
import "./IDMMPool.sol";
import "./PermissionOperators.sol";
import "./Utils.sol";
import "./IERC20Ext.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";


/**
* @dev Contract to calculate expected return amounts for a liquidation call
*   Also work with Kyber Dmm LP tokens
*   Can use hint to:
*     2. Calculate price of a LP token to a dest token
*     3. Calculate price of a normal token to a dest token
*   It may not work for LPs of token with fees
*/
contract KyberDmmChainLinkPriceOracle is ILiquidationPriceOracleBase, PermissionOperators, Utils {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // LIQUIDATE_LP: liquidate list of LP tokens to a single token
  // LIQUIDATE_TOKEN: liquidate list of tokens to a single token
  enum LiquidationType { LIQUIDATE_LP, LIQUIDATE_TOKEN }

  uint64 constant public MAX_PREMIUM_BPS = 2000; // 20%
  // min duration to consider the chainlink rate as a valid data
  uint64 constant public MIN_DURATION_VALID_CHAINLINK_RATE = 30 minutes;

  address public immutable weth;

  struct AggregatorProxyData {
    address quoteEthProxy;
    uint8 quoteEthProxyDecimals;
    address quoteUsdProxy;
    uint8 quoteUsdProxyDecimals;
  }
  mapping (address => AggregatorProxyData) internal _tokenData;

  struct Config {
    uint64 liquidateLpBps;            // default liquidate lp bps
    uint64 liquidateTokenBps;         // default liquidate token bps
    uint64 minValidDurationInSeconds; // min valid duration in seconds for chainlink
    uint64 lpDiffThreshold;           // different threshold for price of 2 tokens in the LP 
  }
  Config internal _config;

  struct PremiumData {
    uint64 liquidateLpBps;
    uint64 liquidateTokenBps;
  }
  mapping (address => PremiumData) internal _groupPremiumData;

  // list of tokens that can be liquidate to
  EnumerableSet.AddressSet private _whitelistedTokens;

  event DefaultPremiumDataSet(
    uint64 liquidateLpBps,
    uint64 liquidateTokenBps
  );
  event UpdateGroupPremiumData(
    address indexed liquidator,
    uint64 liquidateLpBps,
    uint64 liquidateTokenBps
  );
  event UpdateAggregatorProxyData(
    address indexed token,
    address indexed quoteEthProxy,
    address indexed quoteUsdProxy
  );
  event WhitelistedTokenUpdated(address indexed token, bool indexed isAdd);
  event UpdatedMinValidDurationInSeconds(uint64 duration);
  event UpdatedLpDiffThreshold(uint64 threshold);

  constructor(
    address admin,
    address wethAddress,
    address[] memory whitelistedTokens,
    uint64 chainlinkValidDuration,
    uint64 lpDiffThreshold
  ) PermissionAdmin(admin) {
    weth = wethAddress;
    _updateWhitelistedToken(whitelistedTokens, true);
    _setMinValidDuration(chainlinkValidDuration);
    _setLpDiffThreshold(lpDiffThreshold);
  }

  /**
  * @dev Update list of aggregator proxies for tokens
  *   Need to check the data carefully, Aggregator contract doesn't have function to
  *     get the supported token or base, so can not do any safe check here
  *   For flexibility, it should be done by trusted operators
  */
  function updateAggregatorProxyData(
    address[] calldata tokens,
    address[] calldata quoteEthProxies,
    address[] calldata quoteUsdProxies
  ) external onlyOperator {

    require(
      tokens.length == quoteEthProxies.length &&
      tokens.length == quoteUsdProxies.length,
      'invalid length'
    );

    uint8 quoteEthProxyDecimals;
    uint8 quoteUsdProxyDecimals;

    for(uint256 i = 0; i < tokens.length; i++) {
      quoteEthProxyDecimals = quoteEthProxies[i] == address(0) ? 0 :
        IChainLinkAggregatorProxy(quoteEthProxies[i]).decimals();
      quoteUsdProxyDecimals = quoteUsdProxies[i] == address(0) ? 0 :
        IChainLinkAggregatorProxy(quoteUsdProxies[i]).decimals();

      _tokenData[tokens[i]] = AggregatorProxyData({
        quoteEthProxy: quoteEthProxies[i],
        quoteUsdProxy: quoteUsdProxies[i],
        quoteEthProxyDecimals: quoteEthProxyDecimals,
        quoteUsdProxyDecimals: quoteUsdProxyDecimals
      });
      emit UpdateAggregatorProxyData(tokens[i], quoteEthProxies[i], quoteUsdProxies[i]);
    }
  }

  function updateMinValidDuration(uint64 newDuration)
    external onlyOperator
  {
    _setMinValidDuration(newDuration);
  }

  function updateLpDiffThreshold(uint64 threshold)
    external onlyOperator
  {
    _setLpDiffThreshold(threshold);
  }

  function updateGroupPremiumData(
    address[] calldata _liquidators,
    uint64[] calldata _liquidateLpBps,
    uint64[] calldata _liquidateTokenBps
  )
    external onlyAdmin
  {
    require(
      _liquidators.length == _liquidateLpBps.length &&
      _liquidators.length == _liquidateTokenBps.length,
      'invalid length'
    );
    for(uint256 i = 0; i < _liquidators.length; i++) {
      _setGroupPremiumData(
        _liquidators[i],
        _liquidateLpBps[i],
        _liquidateTokenBps[i]
      );
    }
  }

  function updateDefaultPremiumData(
    uint64 _liquidateLpBps,
    uint64 _liquidateTokenBps
  ) external onlyAdmin {
    _setDefaultPremiumData(_liquidateLpBps, _liquidateTokenBps);
  }

  function updateWhitelistedTokens(address[] calldata tokens, bool isAdd)
    external onlyAdmin
  {
    _updateWhitelistedToken(tokens, isAdd);
  }

  /**
   * @dev Return list of min amounts that expected to get in return
   *  when liquidating corresponding list of src tokens
   *  2 LiquidationType for hint: LIQUIDATE_TOKEN, LIQUIDATE_LP
   *  - LIQUIDATE_TOKEN: Liquidate a normal token to the tokenOut (the token should have chainlink data)
   *  - LIQUIDATE_LP: Liquidate a LP token to the tokenOut (underlying tokens should have chainlink data)
   *  Apply premium discount, can be a different value for each liquidator.
   * @param liquidator address of the liquidator
   * @param tokenIns list of src tokens
   * @param amountIns list of src amounts
   * @param tokenOut dest token
   * @param hint hint for getting conversion rates, list of LiquidationType,
   *     corresponding to the list source token
   * @return minAmountOut min expected amount for the token out
   */
  function getExpectedReturn(
    address liquidator,
    IERC20Ext[] calldata tokenIns,
    uint256[] calldata amountIns,
    IERC20Ext tokenOut,
    bytes calldata hint
  )
    external override view
    returns (uint256 minAmountOut)
  {
    require(tokenIns.length == amountIns.length, 'invalid lengths');

    (LiquidationType[] memory hintTypes) = abi.decode(hint, (LiquidationType[]));
    require(hintTypes.length == tokenIns.length, 'invalid lengths');

    require(isWhitelistedToken(address(tokenOut)), 'token out must be whitelisted');

    // get rate data of token out in advance to reduce gas cost
    uint256 tokenOutRateEth = getRateOverEth(address(tokenOut));
    uint256 tokenOutRateUsd = getRateOverUsd(address(tokenOut));

    // total amount out from LP tokens
    uint256 amountOutLpTokens;
    // total amount out from normal tokens
    uint256 amountOutNormalTokens;

    for(uint256 i = 0; i < tokenIns.length; i++) {
      if (hintTypes[i] == LiquidationType.LIQUIDATE_TOKEN) {
        if (tokenIns[i] == tokenOut) {
          // allow to forward a whitelist token from treasury -> reward without premium
          minAmountOut = minAmountOut.add(amountIns[i]);
          continue;
        } else {
          // not allow to liquidate from a whitelisted token to another whitelisted token
          require(
            !isWhitelistedToken(address(tokenIns[i])),
            'token in can not be a whitelisted token'
          );
        }
      }
      uint256 expectedReturn = _getExpectedReturnFromToken(
        tokenIns[i],
        amountIns[i],
        tokenOut,
        tokenOutRateEth,
        tokenOutRateUsd,
        hintTypes[i] == LiquidationType.LIQUIDATE_LP
      );
      if (hintTypes[i] == LiquidationType.LIQUIDATE_LP) {
        amountOutLpTokens = amountOutLpTokens.add(expectedReturn);
      } else {
        amountOutNormalTokens = amountOutNormalTokens.add(expectedReturn);
      }
    }

    (amountOutLpTokens, amountOutNormalTokens) =
      _applyPremiumFor(liquidator, amountOutLpTokens, amountOutNormalTokens);

    minAmountOut = minAmountOut.add(amountOutLpTokens).add(amountOutNormalTokens);
  }

  // Whitelisted tokens
  function getWhitelistedTokensLength() external view returns (uint256) {
    return _whitelistedTokens.length();
  }

  function getWhitelistedTokenAt(uint256 index) external view returns (address) {
    return _whitelistedTokens.at(index);
  }

  function getAllWhitelistedTokens()
    external view returns (address[] memory tokens)
  {
    uint256 length = _whitelistedTokens.length();
    tokens = new address[](length);
    for(uint256 i = 0; i < length; i++) {
      tokens[i] = _whitelistedTokens.at(i);
    }
  }

  /**
   * @dev Return expect amounts given pool and number of lp tokens
   * @return tokens [token0, token1]
   * @return amounts [expectedAmount0, expectedAmount1s, virtualBalance0, virtualBalance1]
   */
  function getExpectedTokensFromLp(
    address pool,
    uint256 lpAmount
  )
    public view
    returns (
      IERC20Ext[2] memory tokens,
      uint256[4] memory amounts
    )
  {
    uint256 totalSupply = IERC20Ext(pool).totalSupply();
    (tokens[0], tokens[1]) = (IDMMPool(pool).token0(), IDMMPool(pool).token1());
    uint256 amount0;
    uint256 amount1;
    (
      amount0,
      amount1,
      amounts[2], // virtual balance 0
      amounts[3], // virtual balance 1
      // fee in precision
    ) = IDMMPool(pool).getTradeInfo();

    (amounts[0], amounts[1]) = (
      amount0.mul(lpAmount) / totalSupply,
      amount1.mul(lpAmount) / totalSupply
    );
  }

  function getTokenAggregatorProxyData(address token)
    external view returns (
      address quoteEthProxy,
      address quoteUsdProxy,
      uint8 quoteEthDecimals,
      uint8 quoteUsdDecimals
    )
  {
    (quoteEthProxy, quoteUsdProxy) = (_tokenData[token].quoteEthProxy, _tokenData[token].quoteUsdProxy);
    (quoteEthDecimals, quoteUsdDecimals) = (
      _tokenData[token].quoteEthProxyDecimals,
      _tokenData[token].quoteUsdProxyDecimals
    );
  }

  function getConfig()
    external view
    returns (
      uint64 liquidateLpBps,
      uint64 liquidateTokenBps,
      uint64 minValidDurationInSeconds,
      uint64 lpDiffThreshold
    )
  {
    (
      liquidateLpBps,
      liquidateTokenBps,
      minValidDurationInSeconds,
      lpDiffThreshold
    ) = (
        _config.liquidateLpBps,
        _config.liquidateTokenBps,
        _config.minValidDurationInSeconds,
        _config.lpDiffThreshold
      );
  }

  /**
  *   @dev Get token rate over eth with units of PRECISION
  */
  function getRateOverEth(address token) public view returns (uint256 rate) {
    if (token == address(ETH_TOKEN_ADDRESS) || token == weth) return PRECISION;
    int256 answer;
    uint256 updatedAt;
    IChainLinkAggregatorProxy proxy = IChainLinkAggregatorProxy(_tokenData[token].quoteEthProxy);
    if (proxy != IChainLinkAggregatorProxy(0)) {
      (, answer, , updatedAt,) = proxy.latestRoundData();
    }
    if (answer <= 0) return 0; // safe check in case ChainLink returns invalid data
    if (updatedAt.add(_config.minValidDurationInSeconds) < block.timestamp) return 0;
    rate = uint256(answer);
    uint256 decimals = uint256(_tokenData[token].quoteEthProxyDecimals);
    rate = (decimals < MAX_DECIMALS) ? rate.mul(10 ** (MAX_DECIMALS - decimals)) :
      rate / (10 ** (decimals - MAX_DECIMALS));
  }

  /**
  *   @dev Get token rate over usd with units of PRECISION
  */
  function getRateOverUsd(address token) public view returns (uint256 rate) {
    int256 answer;
    uint256 updatedAt;
    IChainLinkAggregatorProxy proxy = IChainLinkAggregatorProxy(_tokenData[token].quoteUsdProxy);
    if (proxy != IChainLinkAggregatorProxy(0)) {
      (, answer, , updatedAt,) = proxy.latestRoundData();
    }
    if (answer <= 0) return 0; // safe check in case ChainLink returns invalid data
    if (updatedAt.add(_config.minValidDurationInSeconds) < block.timestamp) return 0;
    rate = uint256(answer);
    uint256 decimals = uint256(_tokenData[token].quoteUsdProxyDecimals);
    rate = (decimals < MAX_DECIMALS) ? rate.mul(10 ** (MAX_DECIMALS - decimals)) :
      rate / (10 ** (decimals - MAX_DECIMALS));
  }

  function isWhitelistedToken(address token)
    public view returns (bool)
  {
    return _whitelistedTokens.contains(token);
  }

  function getPremiumData(address liquidator)
    public view
    returns (
      uint64 liquidateLpBps,
      uint64 liquidateTokenBps
    )
  {
    PremiumData memory data = _groupPremiumData[liquidator];
    if (data.liquidateLpBps == 0 && data.liquidateTokenBps == 0) {
      liquidateLpBps = _config.liquidateLpBps;
      liquidateTokenBps = _config.liquidateTokenBps;
    } else {
      liquidateLpBps = data.liquidateLpBps;
      liquidateTokenBps = data.liquidateTokenBps;
    }
  }

  function _updateWhitelistedToken(address[] memory _tokens, bool _isAdd) internal {
    for(uint256 i = 0; i < _tokens.length; i++) {
      if (_isAdd) {
        _whitelistedTokens.add(_tokens[i]);
      } else {
        _whitelistedTokens.remove(_tokens[i]);
      }
      emit WhitelistedTokenUpdated(_tokens[i], _isAdd);
    }
  }

  function _setDefaultPremiumData(
    uint64 _liquidateLpBps,
    uint64 _liquidateTokenBps
  ) internal {
    require(_liquidateLpBps <= MAX_PREMIUM_BPS, 'invalid liquidate lp bps');
    require(_liquidateTokenBps <= MAX_PREMIUM_BPS, 'invalid liquidate token bps');
    _config.liquidateLpBps = _liquidateLpBps;
    _config.liquidateTokenBps = _liquidateTokenBps;
    emit DefaultPremiumDataSet(_liquidateLpBps, _liquidateTokenBps);
  }

  function _setGroupPremiumData(
    address _liquidator,
    uint64 _liquidateLpBps,
    uint64 _liquidateTokenBps
  ) internal {
    require(_liquidateLpBps <= MAX_PREMIUM_BPS, 'invalid liquidate lp bps');
    require(_liquidateTokenBps <= MAX_PREMIUM_BPS, 'invalid liquidate token bps');
    _groupPremiumData[_liquidator].liquidateLpBps = _liquidateLpBps;
    _groupPremiumData[_liquidator].liquidateTokenBps = _liquidateTokenBps;
    emit UpdateGroupPremiumData(_liquidator, _liquidateLpBps, _liquidateTokenBps);
  }

  function _setMinValidDuration(uint64 _duration) internal {
    require(_duration >= MIN_DURATION_VALID_CHAINLINK_RATE, 'duration is too low');
    _config.minValidDurationInSeconds = _duration;
    emit UpdatedMinValidDurationInSeconds(_duration);
  }

  function _setLpDiffThreshold(uint64 _threshold) internal {
    require(_threshold <= MAX_PREMIUM_BPS, 'threshold is too high');
    _config.lpDiffThreshold = _threshold;
    emit UpdatedLpDiffThreshold(_threshold);
  }

  function _applyPremiumFor(address liquidator, uint256 amountFromLPs, uint256 amountFromTokens)
    internal view
    returns (uint256 amountFromLPsAfter, uint256 amountFromTokensAfter)
  {
    (uint64 premiumLpBps, uint64 premiumTokenBps) = getPremiumData(liquidator);
    if (amountFromLPs > 0) {
      amountFromLPsAfter = amountFromLPs.sub(
        amountFromLPs.mul(premiumLpBps) / BPS
      );
    }
    if (amountFromTokens > 0) {
      amountFromTokensAfter = amountFromTokens.sub(
        amountFromTokens.mul(premiumTokenBps) / BPS
      );
    }
  }

  /**
  *   @dev Get expected return amount from src token given dest token data
  *   Save gas when liquidating multiple tokens or LP tokens
  */
  function _getExpectedReturnFromToken(
    IERC20Ext tokenIn,
    uint256 amountIn,
    IERC20Ext dest,
    uint256 destRateEth,
    uint256 destRateUsd,
    bool isFromLpToken
  )
    internal view
    returns (uint256 totalReturn)
  {
    bool isDestEth = dest == ETH_TOKEN_ADDRESS || dest == IERC20Ext(weth);
    uint256 rate;

    if (!isFromLpToken) {
      rate = isDestEth ? getRateOverEth(address(tokenIn)) :
        _getRateWithDestTokenData(address(tokenIn), destRateEth, destRateUsd);
      require(rate > 0, '0 aggregator rate');
      return _calculateReturnAmount(amountIn, getDecimals(tokenIn), getDecimals(dest), rate);
    }

    (IERC20Ext[2] memory tokens, uint256[4] memory amounts) = getExpectedTokensFromLp(
      address(tokenIn), amountIn
    );

    uint256 destTokenDecimals = getDecimals(dest);
    uint256 totalDestInToken0;
    uint256 totalDestInToken1;

    // calc equivalent (tokens[0], amounts[0]) -> tokenOut
    if (tokens[0] == dest) {
      totalReturn = totalReturn.add(amounts[0]);
      totalDestInToken0 = amounts[2];
    } else {
      rate = isDestEth ? getRateOverEth(address(tokens[0])) :
        _getRateWithDestTokenData(address(tokens[0]), destRateEth, destRateUsd);
      require(rate > 0, '0 aggregator rate');
      uint256 _decimals = getDecimals(tokens[0]);
      totalReturn = totalReturn.add(
        _calculateReturnAmount(amounts[0], _decimals, destTokenDecimals, rate)
      );
      totalDestInToken0 = _calculateReturnAmount(amounts[2], _decimals, destTokenDecimals, rate);
    }

    // calc equivalent (tokens[1], amounts[1]) -> tokenOut
    if (tokens[1] == dest) {
      totalReturn = totalReturn.add(amounts[1]);
      totalDestInToken1 = amounts[3];
    } else {
      rate = isDestEth ? getRateOverEth(address(tokens[1])) :
        _getRateWithDestTokenData(address(tokens[1]), destRateEth, destRateUsd);
        require(rate > 0, '0 aggregator rate');
        uint256 _decimals = getDecimals(tokens[1]);
      totalReturn = totalReturn.add(
        _calculateReturnAmount(amounts[1], _decimals, destTokenDecimals, rate)
      );
      totalDestInToken1 = _calculateReturnAmount(amounts[3], _decimals, destTokenDecimals, rate);
    }
    // verify if equivalent dest tokens from virtual balances is within the threshold
    // note: if the pool is out of support price range, most likely this check will fail
    if (totalDestInToken0 < totalDestInToken1) {
      require(
        totalDestInToken0.mul(BPS + _config.lpDiffThreshold) >= totalDestInToken1.mul(BPS),
        'lpDiffThreshold: out of range'
      );
    } else {
      require(
        totalDestInToken1.mul(BPS + _config.lpDiffThreshold) >= totalDestInToken0.mul(BPS),
        'lpDiffThreshold: out of range'
      );
    }
  }

  /**
  *   @dev Get rate from src token given dest token rates over eth and usd
  *   It is used to save gas when liquidating multiple tokens or LP tokens
  */
  function _getRateWithDestTokenData(
    address src,
    uint256 destTokenRateEth,
    uint256 destTokenRateUsd
  ) internal view returns (uint256) {
    if (src == address(ETH_TOKEN_ADDRESS) || src == weth) {
      if (destTokenRateEth == 0) return 0;
      return PRECISION.mul(PRECISION) / destTokenRateEth;
    }

    uint256 rateQuoteEth;
    uint256 rateQuoteUsd;

    if (destTokenRateEth > 0) {
      uint256 srcTokenRateEth = getRateOverEth(src);
      rateQuoteEth = PRECISION.mul(srcTokenRateEth) / destTokenRateEth;
    }

    if (destTokenRateUsd > 0) {
      uint256 srcTokenRateUsd = getRateOverUsd(src);
      rateQuoteUsd = PRECISION.mul(srcTokenRateUsd) / destTokenRateUsd;
    }

    if (rateQuoteEth == 0) return rateQuoteUsd;
    if (rateQuoteUsd == 0) return rateQuoteEth;
    return rateQuoteEth.add(rateQuoteUsd) / 2;
  }

  function _calculateReturnAmount(
    uint256 srcQty,
    uint256 srcDecimals,
    uint256 dstDecimals,
    uint256 rate
  ) internal pure returns (uint256) {
    if (dstDecimals >= srcDecimals) {
      require(dstDecimals - srcDecimals <= MAX_DECIMALS, 'dst - src > MAX_DECIMALS');
      return srcQty.mul(rate).mul(10**(dstDecimals - srcDecimals)) / PRECISION;
    }
    require(srcDecimals - dstDecimals <= MAX_DECIMALS, 'src - dst > MAX_DECIMALS');
    return srcQty.mul(rate) / (PRECISION.mul(10**(srcDecimals - dstDecimals)));
  }
}
