// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.20;

import "./IKeeperOracles.sol";
import "./IKeeperValidators.sol";
import "./IKeeperRewards.sol";

/**
 * @title IKeeper
 * @author StakeWise
 * @notice Defines the interface for the Keeper contract
 */
interface IKeeper is IKeeperOracles, IKeeperRewards, IKeeperValidators {
  /**
   * @notice Initializes the Keeper contract. Can only be called once.
   * @param _owner The address of the owner
   */
  function initialize(address _owner) external;
}
