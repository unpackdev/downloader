// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";

/**
 * @title BendCollector
 * @notice Stores all the BEND kept for incentives, just giving approval to the different
 * systems that will pull BEND funds for their specific use case
 * @author Bend
 **/
contract BendCollector is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev initializes the contract upon assignment to the BendUpgradeableProxy
   */
  function initialize() external initializer {
    __Ownable_init();
  }

  function approve(
    IERC20Upgradeable token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.safeApprove(recipient, amount);
  }

  function transfer(
    IERC20Upgradeable token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.safeTransfer(recipient, amount);
  }
}
