// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./VersionedInitializable.sol";
import "./IERC20.sol";

/**
 * @title Treasury 
 * @notice Stores DYDX kept for incentives, just giving approval to the different
 * systems that will pull DYDX funds for their specific use case.
 * @author dYdX
 **/
contract Treasury is
OwnableUpgradeable,
VersionedInitializable
{
  using SafeERC20 for IERC20;

  uint256 public constant REVISION = 1;

  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize() external initializer {
    __Ownable_init();
  }

  function approve(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    // SafeERC20 safeApprove requires setting to zero first.
    IERC20(token).safeApprove(recipient, 0);
    IERC20(token).safeApprove(recipient, amount);
  }

  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).safeTransfer(recipient, amount);
  }
}
