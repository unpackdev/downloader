// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationCompatibleInterface.sol";

/**
 * @title IGovernanceChainRobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions for the governance.
 **/
interface IGovernanceChainRobotKeeper is AutomationCompatibleInterface {
  /**
   * @notice Emitted when performUpkeep is called and an action is executed.
   * @param id proposal id of successful action.
   * @param action successful action performed on the proposal.
   */
  event ActionSucceeded(uint256 indexed id, ProposalAction indexed action);

  /**
   * @notice Actions that can be performed by the robot for governance v3.
   * PerformActivateVoting: performs activate voting action on the governance contract.
   * PerformExecute: performs execute action on the governance contract.
   * PerformCancel: performs cancel action on the governance contract.
   **/
  enum ProposalAction {
    PerformActivateVoting,
    PerformExecute,
    PerformCancel
  }

  /**
   * @notice holds action to be performed for a given proposalId.
   * @param id proposal id for which action needs to be performed.
   * @param action action to be perfomed for the proposalId.
   */
  struct ActionWithId {
    uint256 id;
    ProposalAction action;
  }

  /**
   * @notice method to check if a proposalId is disabled.
   * @param id proposalId to check if it is disabled.
   * @return bool if proposal is disabled or not.
   **/
  function isDisabled(uint256 id) external view returns (bool);

  /**
   * @notice method called by owner to disable/enabled automation on a specific proposalId.
   * @param proposalId proposalId for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 proposalId) external;

  /**
   * @notice method to get the address of the governance contract.
   * @return governance contract address.
   */
  function GOVERNANCE() external returns (address);

  /**
   * @notice method to get the maximum number of actions that can be performed by the keeper in one performUpkeep.
   * @return max number of actions.
   */
  function MAX_ACTIONS() external returns (uint256);

  /**
   * @notice method to get maximum number of proposals to check before the latest proposal, if an action could be performed upon.
   * @return max number of skips.
   */
  function MAX_SKIP() external returns (uint256);
}
