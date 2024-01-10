// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./SafeERC20.sol";
import "./CurveStable.sol";
import "./ConvexBase.sol";

/// @notice Implements the strategy using Convex. The steps are similar to CurveStable strategy, the main differences are:
///  1) The Curve LP tokens are deposited into Convex Booster contract
///  2) Use the Convex Rewards contract to claim rewards and get both CRV and CVX in return
///  Because of this, the strategy only overrides some of the functions from parent contracts for the different parts.
/// Booster: 0xF403C135812408BFbE8713b5A23a04b3D48AAE31
/// Rewards: 0x4a2631d090e8b40bBDe245e687BF09e5e534A239
/// Pool Id: 13 (This id is used by Convex to look up pool information in the booster)
contract ConvexStable is CurveStable, ConvexBase {
  using SafeERC20 for IERC20;

  uint256 private constant POOL_ID = 13;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool,
    address _booster
  ) CurveStable(_vault, _proposer, _developer, _keeper, _pool) ConvexBase(POOL_ID, _booster) {}

  function name() external view override returns (string memory) {
    return string(abi.encodePacked("ConvexStable_", IERC20Metadata(address(want)).symbol()));
  }

  function protectedTokens() internal view virtual override returns (address[] memory) {
    return _buildProtectedTokens(_getCurveTokenAddress());
  }

  function _approveDex() internal virtual override {
    super._approveDex();
    _approveDexExtra(dex);
  }

  function _balanceOfPool() internal view virtual override returns (uint256) {
    // get staked cvxusdn3crv
    uint256 convexBalance = _getLpTokenBalance();
    // staked convex converts 1 to 1 to usdn3crv so no need to calc
    // convert usdn3crv to want
    if (convexBalance > 0) {
      return _quoteWantInMetapoolLp(convexBalance);
    } else {
      return 0;
    }
  }

  function _balanceOfRewards() internal view virtual override returns (uint256) {
    return _convexRewardsValue(_getCurveTokenAddress(), _getQuoteForTokenToWant);
  }

  function _depositLPTokens() internal virtual override {
    _depositToConvex();
  }

  function _claimRewards() internal virtual override {
    _claimConvexRewards(_getCurveTokenAddress(), _swapToWant);
  }

  function _getLpTokenBalance() internal view virtual override returns (uint256) {
    return _getConvexBalance();
  }

  function _removeLpToken(uint256 _amount) internal virtual override {
    _withdrawFromConvex(_amount);
  }

  // no need to do anything
  function onHarvest() internal virtual override {}
}
