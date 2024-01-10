// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./Math.sol";
import "./ICurveDeposit.sol";
import "./ICurveGauge.sol";
import "./ICurveMinter.sol";
import "./IUniswapV2Router.sol";
import "./CurveBase.sol";

/// @notice Implements the strategy using the usdn/3Crv(DAI/USDC/USDT) pool.
///  There is a zap depositor available, however, we came across an error when we tried to use it, and can't figure out a fix, that's why it's not used.
///  So the strategy will deploy the input token (USDC) to the 3Crv pool first, and then deploy the 3Crv LP token to the meta pool.
///  Finally, the strategy will deposit the meta pool LP tokens into the gauge.
///  Input token: USDC
///  Base pool: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7 (3Crv pool)
///  Meta pool: 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1
///  Gauge: 0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4
contract CurveStable is CurveBase {
  using SafeERC20 for IERC20;
  using Address for address;

  // the address of the meta pool
  address internal constant USDN_METAPOOL = address(0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1);
  // the address of the gauge
  address internal constant CURVE_GAUGE = address(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);
  // the address of the 3Crv pool LP token
  IERC20 internal constant THREE_CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
  // the address of the usdn/3Crv meta pool LP token
  IERC20 internal constant USDN_3CRV = IERC20(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522);

  ICurveDeposit internal usdnMetaPool;
  IERC20 internal triPoolLpToken;
  // the index of the want token in the 3Crv pool
  int128 internal immutable wantThreepoolIndex;
  uint256 internal constant N_POOL_COINS = 3;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool
  ) CurveBase(_vault, _proposer, _developer, _keeper, _pool) {
    // threePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // usdnMetaPool = 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1;
    // curveGauge = address(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);
    // curveMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    usdnMetaPool = ICurveDeposit(_getMetaPool());
    triPoolLpToken = _getTriPoolLpToken();
    wantThreepoolIndex = _getWantIndexInCurvePool(_pool);
    _approveCurveExtra();
  }

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked("CurveStable_", IERC20Metadata(address(want)).symbol()));
  }

  function _getMetaPool() internal view virtual returns (address) {
    return USDN_METAPOOL;
  }

  function _getTriPoolLpToken() internal view virtual returns (IERC20) {
    return THREE_CRV;
  }

  function _getMetaPoolLpToken() internal view virtual returns (IERC20) {
    return USDN_3CRV;
  }

  function _getWantTokenIndex() internal view override returns (uint256) {
    return uint128(wantThreepoolIndex);
  }

  function _getCoinsCount() internal pure override returns (uint256) {
    return N_POOL_COINS;
  }

  function _getWantIndexInCurvePool(address _pool) internal view returns (int128) {
    address _candidate;
    for (uint256 i = 0; i < N_POOL_COINS; i++) {
      _candidate = ICurveDeposit(_pool).coins(uint256(i));
      if (address(want) == _candidate) {
        return int128(uint128(i));
      }
    }
    revert("Want token doesnt match any tokens in the curve pool");
  }

  function _balanceOfPool() internal view virtual override returns (uint256) {
    uint256 lpTokenAmount = curveGauge.balanceOf(address(this));
    // we will get the eth amount, which is the same as weth
    if (lpTokenAmount > 0) {
      uint256 outputAmount = _quoteWantInMetapoolLp(lpTokenAmount);
      return outputAmount;
    }
    return 0;
  }

  /// @dev The input is the LP token of the meta pool. To get the value of the original liquidity in the base pool,
  ///  we need to use `calc_withdraw_one_coin` from meta pool and base pool to see how much `want` we will get if we withdraw, without actually doing the withdraw.
  function _quoteWantInMetapoolLp(uint256 _metaPoolLpTokens) public view returns (uint256) {
    uint256 _3crvInUsdn3crv = usdnMetaPool.calc_withdraw_one_coin(_metaPoolLpTokens, 1);
    uint256 _wantIn3crv = curvePool.calc_withdraw_one_coin(_3crvInUsdn3crv, wantThreepoolIndex);
    return _wantIn3crv;
  }

  function _approveCurveExtra() internal virtual {
    want.safeApprove(address(curvePool), type(uint256).max);
    _getTriPoolLpToken().safeApprove(address(usdnMetaPool), type(uint256).max);
  }

  function _addLiquidityToCurvePool() internal virtual override {
    uint256 _wantBalance = _balanceOfWant();
    if (_wantBalance > 0) {
      uint256[3] memory _tokens = _buildDepositArray(_wantBalance);
      curvePool.add_liquidity(_tokens, 0);
    }

    // stake 3crv and recevice usdnMetaPool LP tokens - _getMetaPoolLpToken()
    uint256 _3crv = _getTriPoolLpToken().balanceOf(address(this));
    if (_3crv > 0) {
      // uint256 _usdn3crvLPs2 = usdnMetaPool.add_liquidity([uint256(0), _3crv], uint256(0));
      usdnMetaPool.add_liquidity([uint256(0), _3crv], uint256(0));
    }
  }

  function _depositLPTokens() internal virtual override {
    uint256 _usdn3crvLPs = _getMetaPoolLpToken().balanceOf(address(this));
    if (_usdn3crvLPs > 0) {
      // add usdn3crvLp tokens to curvegauge, this allow to call mint to receive CRV tokens
      curveGauge.deposit(_usdn3crvLPs);
      curveGauge.balanceOf(address(this));
    }
  }

  function _buildDepositArray(uint256 _amount) public view returns (uint256[3] memory) {
    uint256[3] memory _tokenBins;
    _tokenBins[uint128(wantThreepoolIndex)] = _amount;
    return _tokenBins;
  }

  /// @dev The `_amount` is in want token, so we need to convert that to LP tokens first.
  ///  We use the `calc_token_amount` to calculate how many LP tokens we will get with the `_amount` of want tokens without actually doing the deposit.
  ///  Then we add a bit more (2%) for padding.
  function _withdrawSome(uint256 _amount) internal override returns (uint256) {
    uint256 requiredTriPoollLpTokens = curvePool.calc_token_amount(_buildDepositArray(_amount), true);
    uint256 requiredMetaPoollLpTokens = (usdnMetaPool.calc_token_amount([0, requiredTriPoollLpTokens], true) * 10200) /
      10000; // adding 2% for fees
    uint256 liquidated = _removeLiquidity(requiredMetaPoollLpTokens);
    return liquidated;
  }

  function _getCurvePoolGaugeAddress() internal view virtual override returns (address) {
    return CURVE_GAUGE;
  }

  /// @dev Remove the liquidity by the LP token amount
  /// @param _amount The amount of LP token (not want token)
  function _removeLiquidity(uint256 _amount) internal override returns (uint256) {
    uint256 _before = _balanceOfWant();
    uint256 lpBalance = _getLpTokenBalance();
    // need to make sure we don't withdraw more than what we have
    uint256 withdrawAmount = Math.min(lpBalance, _amount);
    // withdraw this amount of lp tokens first
    _removeLpToken(withdrawAmount);
    // then remove the liqudity from the pool, will get want back
    uint256 usdn3crv = _getMetaPoolLpToken().balanceOf(address(this));
    usdnMetaPool.remove_liquidity_one_coin(usdn3crv, 1, uint256(0));
    uint256 _3crv = _getTriPoolLpToken().balanceOf(address(this));
    ICurveDepositTrio(address(curvePool)).remove_liquidity_one_coin(_3crv, wantThreepoolIndex, 0);
    return _balanceOfWant() - _before;
  }
}
