// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "./SafeERC20.sol";
import "./CurveBtc.sol";
import "./ConvexBase.sol";

/// @notice Implements the strategy using Convex. The steps are similar to CurveBtc strategy, the main differences are:
///  1) The Curve LP tokens are deposited into Convex Booster contract
///  2) Use the Convex Rewards contract to claim rewards and get both CRV and CVX in return
///  Because of this, the strategy only overrides some of the functions from parent contracts for the different parts.
/// Booster: 0xF403C135812408BFbE8713b5A23a04b3D48AAE31
/// Rewards: 0xeeeCE77e0bc5e59c77fc408789A9A172A504bD2f
/// Pool Id: 20 (This id is used by Convex to look up pool information in the booster)
contract ConvexBtc is CurveBtc, ConvexBase {
  using SafeERC20 for IERC20;

  uint256 private constant POOL_ID = 20;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool,
    address _booster
  ) CurveBtc(_vault, _proposer, _developer, _keeper, _pool) ConvexBase(POOL_ID, _booster) {}

  function name() external pure override returns (string memory) {
    return "ConvexBTC";
  }

  function protectedTokens() internal view virtual override returns (address[] memory) {
    return _buildProtectedTokens(_getCurveTokenAddress());
  }

  function _approveDex() internal virtual override {
    super._approveDex();
    _approveDexExtra(dex);
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
