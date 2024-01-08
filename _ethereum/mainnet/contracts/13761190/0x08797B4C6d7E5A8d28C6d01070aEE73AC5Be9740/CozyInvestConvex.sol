// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./ICozyInvest.sol";
import "./CozyInvestHelpers.sol";

interface IConvexBooster {
  // Returns: lptoken, token, gauge, crvRewards, stash, shutdown
  function poolInfo(uint256)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      bool
    );

  function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

interface IConvexRewardManager {
  function extraRewards(uint256 index) external returns (address);

  function extraRewardsLength() external returns (uint256);

  function getReward(address _account, bool _claimExtras) external returns (bool);

  function rewardToken() external returns (IERC20);

  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

interface ICrvDepositZap {
  function add_liquidity(uint256[4] calldata amounts, uint256 minMintAmount) external returns (uint256);

  function add_liquidity(
    address pool,
    uint256[4] calldata amounts,
    uint256 minMintAmount
  ) external returns (uint256);

  function calc_withdraw_one_coin(
    address pool,
    uint256 amount,
    uint128 index
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 amount,
    int128 index,
    uint256 minAmount
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    address pool,
    uint256 amount,
    int128 index,
    uint256 minAmount
  ) external returns (uint256);
}

/**
 * @notice On-chain scripts for borrowing from Cozy and using the borrowed funds to
 * supply to curve and then deposit into Convex
 * @dev This contract is intended to be used by delegatecalling to it from a DSProxy
 */
contract CozyInvestConvex is CozyInvestHelpers, ICozyInvest5, ICozyDivest5, ICozyReward {
  using SafeERC20 for IERC20;

  /// @notice The unprotected money market we borrow from / repay to
  address public immutable moneyMarket;
  /// @notice The protection market we borrow from / repay to
  address public immutable protectionMarket;
  /// @notice Underlying of the above money market and protection market
  address public immutable underlying;
  /// @notice Curve deposit zap
  address public immutable curveDepositZap;
  /// @notice Token index for the curve pool
  int128 public immutable curveIndex;
  /// @notice Curve LP token
  address public immutable curveLpToken;
  /// @notice Convex booster id
  uint256 public immutable convexPoolId;
  /// @notice Convex reward manager
  address public immutable convexRewardManager;

  /// @notice Curve metapool
  bool public immutable longSigFormat;

  /// @notice Convex deposit contract address
  address public constant convex = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

  /// @notice Curve DAI/USDC/USDT (3Crv) pool
  address public constant tricurve = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

  constructor(
    address _moneyMarket,
    address _protectionMarket,
    address _underlying,
    address _curveDepositZap,
    uint256 _convexPoolId,
    int128 _curveIndex,
    bool _longSigFormat
  ) {
    moneyMarket = _moneyMarket;
    protectionMarket = _protectionMarket;
    underlying = _underlying;
    curveDepositZap = _curveDepositZap;
    convexPoolId = _convexPoolId;
    longSigFormat = _longSigFormat;
    curveIndex = _curveIndex;

    (address _curveLpToken, , , address _convexRewardManager, , ) = IConvexBooster(convex).poolInfo(convexPoolId);
    curveLpToken = _curveLpToken;
    convexRewardManager = _convexRewardManager;
  }

  /**
   * @notice Invest method for borrowing underlying and depositing it to Curve and then Convex
   * @param _market Address of the market to repay
   * @param _borrowAmount Amount of underlying to borrow and invest
   * @param _curveMinAmountOut The minimum amount we expect to receive when adding liquidity to Curve
   */
  function invest(
    address _market,
    uint256 _borrowAmount,
    uint256 _curveMinAmountOut
  ) external {
    // 1. Borrow underlying from cozy
    require((_market == address(moneyMarket) || _market == address(protectionMarket)), "Invalid borrow market");
    require(ICozyToken(_market).borrow(_borrowAmount) == 0, "Borrow failed");

    // 2. Approve curve deposit zap to spend the underlying so it can deposit into curve pool
    IERC20(underlying).safeApprove(curveDepositZap, 0);
    IERC20(underlying).safeApprove(curveDepositZap, type(uint256).max);

    // 3. Deposit into curve pool
    uint256[4] memory _tokenAmounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
    _tokenAmounts[uint256(uint128(curveIndex))] = _borrowAmount;
    if (longSigFormat) {
      // Metapool requires curve pool address to be specified in first argument.
      ICrvDepositZap(curveDepositZap).add_liquidity(curveLpToken, _tokenAmounts, _curveMinAmountOut);
    } else {
      ICrvDepositZap(curveDepositZap).add_liquidity(_tokenAmounts, _curveMinAmountOut);
    }

    // 4. Safe approve curve pool receipt token to deposit into convex booster contract
    IERC20(curveLpToken).safeApprove(convex, 0);
    IERC20(curveLpToken).safeApprove(convex, type(uint256).max);

    // 5. Deposit into convex booster contract (call depositAll with _pid, and _stake = true)
    IConvexBooster(convex).depositAll(convexPoolId, true);
  }

  /**
   * @notice Protected divest method for exiting a position entered using this contract's `invest` method
   * @param _market Address of the market to repay debt to
   * @param _recipient Address where any leftover funds should be transferred
   * @param _withdrawAmount Amount of Curve receipt tokens to redeem
   * @param _excessTokens Quantity to transfer from the caller into this address to ensure
   * the borrow can be repaid in full.
   * @param _curveMinAmountOut The minAmountOut we expect to receive when removing liquidity from Curve
   */
  function divest(
    address _market,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens,
    uint256 _curveMinAmountOut
  ) external {
    require((_market == moneyMarket || _market == protectionMarket), "Invalid borrow market");

    // 1. Withdraw from convex
    IConvexRewardManager _convexRewardManager = IConvexRewardManager(convexRewardManager);
    _convexRewardManager.withdrawAndUnwrap(_withdrawAmount, false);

    // 2. Withdraw from curve
    // There are two kinds of curve zaps -- one requires curve pool to be specified in first argument.
    // Approve Curve's depositZap to spend our receipt tokens
    IERC20(curveLpToken).safeApprove(curveDepositZap, 0);
    IERC20(curveLpToken).safeApprove(curveDepositZap, type(uint256).max);
    if (longSigFormat) {
      ICrvDepositZap(curveDepositZap).remove_liquidity_one_coin(
        curveLpToken,
        _withdrawAmount,
        curveIndex,
        _curveMinAmountOut
      );
    } else {
      ICrvDepositZap(curveDepositZap).remove_liquidity_one_coin(_withdrawAmount, curveIndex, _curveMinAmountOut);
    }

    // Pay back as much of the borrow as possible, excess is refunded to `recipient`
    executeMaxRepay(_market, address(underlying), _excessTokens);

    // Transfer any remaining tokens to the user after paying back borrow
    IERC20(underlying).transfer(_recipient, IERC20(underlying).balanceOf(address(this)));
    claimRewards(_recipient);
  }

  /**
   * @notice Method to claim rewards from Convex
   * @param _recipient Address of the owner's wallet
   */
  function claimRewards(address _recipient) public {
    IConvexRewardManager _convexRewardManager = IConvexRewardManager(convexRewardManager);
    _convexRewardManager.getReward(address(this), true);

    IERC20 _rewardToken = IERC20(_convexRewardManager.rewardToken());
    _rewardToken.transfer(_recipient, _rewardToken.balanceOf(address(this)));

    uint256 _extraRewardsLength = _convexRewardManager.extraRewardsLength();
    for (uint256 i = 0; i < _extraRewardsLength; i++) {
      IConvexRewardManager _extraRewardManager = IConvexRewardManager(_convexRewardManager.extraRewards(i));
      IERC20 _extraRewardToken = IERC20(_extraRewardManager.rewardToken());
      _extraRewardToken.transfer(_recipient, _extraRewardToken.balanceOf(address(this)));
    }
  }
}
