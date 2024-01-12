// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "./VersionedInitializable.sol";

/**
 * @title IncentivesVault
 * @notice Stores all the AAVE kept for incentives, just giving approval to the different
 * systems that will pull AAVE funds for their specific use case
 * @author Vinci
 **/
contract IncentivesVault is VersionedInitializable {

  uint256 public constant REVISION = 1;

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal override pure returns (uint256) {
    return REVISION;
  }

  /**
   * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
   */
  function initialize() external initializer {
  }
}