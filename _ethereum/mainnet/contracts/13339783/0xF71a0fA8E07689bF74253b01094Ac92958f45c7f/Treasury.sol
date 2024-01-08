// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./VersionedInitializable.sol";
import "./MarketAccessBitmask.sol";
import "./IMarketAccessController.sol";
import "./AccessFlags.sol";
import "./IRewardCollector.sol";

contract Treasury is VersionedInitializable, MarketAccessBitmask {
  using SafeERC20 for IERC20;
  uint256 private constant TREASURY_REVISION = 1;

  address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor() MarketAccessBitmask(IMarketAccessController(address(0))) {}

  // This initializer is invoked by AccessController.setAddressAsImpl
  function initialize(address remoteAcl) external virtual initializer(TREASURY_REVISION) {
    _remoteAcl = IMarketAccessController(remoteAcl);
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return TREASURY_REVISION;
  }

  function approveToken(
    address token,
    address recipient,
    uint256 amount
  ) external aclHas(AccessFlags.TREASURY_ADMIN) {
    IERC20(token).safeApprove(recipient, amount);
  }

  function transferToken(
    address token,
    address recipient,
    uint256 amount
  ) external aclHas(AccessFlags.TREASURY_ADMIN) {
    if (token == ETH) {
      Address.sendValue(payable(recipient), amount);
      return;
    }

    if (token == _remoteAcl.getAddress(AccessFlags.REWARD_TOKEN) && IERC20(token).balanceOf(address(this)) < amount) {
      _claimRewards();
    }
    IERC20(token).safeTransfer(recipient, amount);
  }

  function _claimRewards() private {
    address rc = _remoteAcl.getAddress(AccessFlags.REWARD_CONTROLLER);
    if (rc != address(0)) {
      IRewardCollector(rc).claimReward();
    }
  }

  function claimRewardsForTreasury() external aclHas(AccessFlags.TREASURY_ADMIN) {
    _claimRewards();
  }
}
