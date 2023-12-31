// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationCompatibleInterface.sol";

/**
 * @title IVotingChainRobotKeeper
 * @author BGD Labs
 * @notice Defines the interface for the contract to automate actions for voting machine, data warehouse on the voting chain.
 **/
interface IVotingChainRobotKeeper is AutomationCompatibleInterface {
  /**
   * @notice Emitted when performUpkeep is called and an action is executed.
   * @param id proposal id of successful action.
   * @param action successful action performed on the proposal.
   */
  event ActionSucceeded(uint256 indexed id, ProposalAction indexed action);

  /**
   * @notice Actions that can be performed by the robot for governance v3.
   * PerformSubmitRoots: performs requestSubmitRoots action on the Chainlink API consumer contract.
   *                     which submits the roots to Data warehouse contract via a callback function.
   * PerformCreateVote: performs createVote action on the voting machine contract.
   * PerformCloseAndSendVote: performs createVote action on the voting machine contract.
   **/
  enum ProposalAction {
    PerformSubmitRoots,
    PerformCreateVote,
    PerformCloseAndSendVote
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
   * @param id - proposalId to check if disabled.
   * @return bool if proposal is disabled or not.
   **/
  function isDisabled(uint256 id) external view returns (bool);

  /**
   * @notice method called by owner to disable/enabled automation on a specific proposalId.
   * @param proposalId proposalId for which we need to disable/enable automation.
   */
  function toggleDisableAutomationById(uint256 proposalId) external;

  /**
   * @notice method to retry submitting roots for the blockhash of the proposal. This is required incase the
   *         chainlink node operator fail to perform the operation and we wish to retry.
   * @param proposalId - proposalId for which submit roots needs to be retryed.
   **/
  function retrySubmitRoots(uint256 proposalId) external;

  /**
   * @notice method to get the address of the voting machine contract.
   * @return voting machine contract address.
   */
  function VOTING_MACHINE() external view returns (address);

  /**
   * @notice method to get the address of the voting strategy contract.
   * @return voting strategy contract address.
   */
  function VOTING_STRATEGY() external view returns (address);

  /**
   * @notice method to get the address of the roots consumer contract.
   * @return roots consumer contract address.
   */
  function ROOTS_CONSUMER() external view returns (address);

  /**
   * @notice method to get the address of the data warehouse contract.
   * @return address of the data warehouse contract.
   */
  function DATA_WAREHOUSE() external view returns (address);

  /**
   * @notice method to get the maximum number of actions that can be performed by the keeper in one performUpkeep.
   * @return max number of actions.
   */
  function MAX_ACTIONS() external view returns (uint256);

  /**
   * @notice method to get the size of the proposal list to fetch from last/latest to check if an action could be performed upon.
   * @return size of the proposal list to check.
   */
  function SIZE() external view returns (uint256);
}
