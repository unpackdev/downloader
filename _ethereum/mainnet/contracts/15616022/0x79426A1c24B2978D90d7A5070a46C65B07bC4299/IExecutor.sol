pragma solidity ^0.8.0;

import "./IAaveGovernanceV2.sol";

interface IExecutor {
  /**
  * -------------------------------------------------------------
  * --------------- IExecutorWithTimelock --------------------------
  * -------------------------------------------------------------
  */
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
   event NewPendingAdmin(address newPendingAdmin);

   /**
    * @dev emitted when a new admin is set
    * @param newAdmin address of the new admin
    **/
   event NewAdmin(address newAdmin);
 
   /**
    * @dev emitted when a new delay (between queueing and execution) is set
    * @param delay new delay
    **/
   event NewDelay(uint256 delay);
 
   /**
    * @dev emitted when a new (trans)action is Queued.
    * @param actionHash hash of the action
    * @param target address of the targeted contract
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   event QueuedAction(
     bytes32 actionHash,
     address indexed target,
     uint256 value,
     string signature,
     bytes data,
     uint256 executionTime,
     bool withDelegatecall
   );
 
   /**
    * @dev emitted when an action is Cancelled
    * @param actionHash hash of the action
    * @param target address of the targeted contract
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   event CancelledAction(
     bytes32 actionHash,
     address indexed target,
     uint256 value,
     string signature,
     bytes data,
     uint256 executionTime,
     bool withDelegatecall
   );
 
   /**
    * @dev emitted when an action is Cancelled
    * @param actionHash hash of the action
    * @param target address of the targeted contract
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    * @param resultData the actual callData used on the target
    **/
   event ExecutedAction(
     bytes32 actionHash,
     address indexed target,
     uint256 value,
     string signature,
     bytes data,
     uint256 executionTime,
     bool withDelegatecall,
     bytes resultData
   );

   /**
    * @dev Getter of the current admin address (should be governance)
    * @return The address of the current admin 
    **/
   function getAdmin() external view returns (address);

   /**
    * @dev Getter of the current pending admin address
    * @return The address of the pending admin 
    **/
   function getPendingAdmin() external view returns (address);

   /**
    * @dev Getter of the delay between queuing and execution
    * @return The delay in seconds
    **/
   function getDelay() external view returns (uint256);

   /**
    * @dev Returns whether an action (via actionHash) is queued
    * @param actionHash hash of the action to be checked
    * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
    * @return true if underlying action of actionHash is queued
    **/
   function isActionQueued(bytes32 actionHash) external view returns (bool);

   /**
    * @dev Checks whether a proposal is over its grace period 
    * @param governance Governance contract
    * @param proposalId Id of the proposal against which to test
    * @return true of proposal is over grace period
    **/
   function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
     external
     view
     returns (bool);

   /**
    * @dev Getter of grace period constant
    * @return grace period in seconds
    **/
   function GRACE_PERIOD() external view returns (uint256);

   /**
    * @dev Getter of minimum delay constant
    * @return minimum delay in seconds
    **/
   function MINIMUM_DELAY() external view returns (uint256);

   /**
    * @dev Getter of maximum delay constant
    * @return maximum delay in seconds
    **/
   function MAXIMUM_DELAY() external view returns (uint256);

   /**
   * @dev Set the delay
   * @param delay time in seconds between queue and execution of proposal
   **/
  function setDelay(uint256 delay) external;

  /**
   * @dev Function enabling pending admin to become admin
   **/
   function acceptAdmin() external;

  /**
   * @dev Setting a new pending admin (that can then become admin)
   * Can only be called by this executor (i.e via proposal)
   * @param newPendingAdmin address of the new admin
   **/
  function setPendingAdmin(address newPendingAdmin) external;

   /**
    * @dev Function, called by Governance, that queue a transaction, returns action hash
    * @param target smart contract target
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   function queueTransaction(
     address target,
     uint256 value,
     string memory signature,
     bytes memory data,
     uint256 executionTime,
     bool withDelegatecall
   ) external returns (bytes32);
   /**
    * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
    * @param target smart contract target
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   function executeTransaction(
     address target,
     uint256 value,
     string memory signature,
     bytes memory data,
     uint256 executionTime,
     bool withDelegatecall
   ) external payable returns (bytes memory);
   /**
    * @dev Function, called by Governance, that cancels a transaction, returns action hash
    * @param target smart contract target
    * @param value wei value of the transaction
    * @param signature function signature of the transaction
    * @param data function arguments of the transaction or callData if signature empty
    * @param executionTime time at which to execute the transaction
    * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
    **/
   function cancelTransaction(
     address target,
     uint256 value,
     string memory signature,
     bytes memory data,
     uint256 executionTime,
     bool withDelegatecall
   ) external returns (bytes32);

  /**
  * -------------------------------------------------------------
  * --------------- Proposal Validator --------------------------
  * -------------------------------------------------------------
  */
  // event triggered when voting duration gets updated by the admin
  event VotingDurationUpdated(uint256 newVotingDuration);
  // event triggered when vote differential gets updated by the admin
  event VoteDifferentialUpdated(uint256 newVoteDifferential);
  // event triggered when minimum quorum gets updated by the admin
  event MinimumQuorumUpdated(uint256 newMinimumQuorum);
  // event triggered when proposition threshold gets updated by the admin
  event PropositionThresholdUpdated(uint256 newPropositionThreshold);
  
  /**
  * @dev method tu update the voting duration of the proposal. Only callable by admin.
  * @param votingDuration duration of the vote, in blocks
  */
  function updateVotingDuration(uint256 votingDuration) external;

  /**
  * @dev method to update the vote differential needed to pass the proposal. Only callable by admin.
  * @param voteDifferential differential needed on the votes to pass the proposal
  */
  function updateVoteDifferential(uint256 voteDifferential) external;

  /**
  * @dev method to update the minimum quorum needed to pass the proposal. Only callable by admin.
  * @param minimumQuorum quorum needed to pass the proposal 
  */
  function updateMinimumQuorum(uint256 minimumQuorum) external;

  /**
    * @dev method to update the propositionThreshold. Only callable by admin.
    * @param propositionThreshold new proposition threshold
    **/
  function updatePropositionThreshold(uint256 propositionThreshold) external;

  /**
   * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be created
   **/
  function validateCreatorOfProposal(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance Governance Contract
   * @param user Address of the proposal creator
   * @param blockNumber Block Number against which to make the test (e.g proposal creation block -1).
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Returns whether a user has enough Proposition Power to make a proposal.
   * @param governance Governance Contract
   * @param user Address of the user to be challenged.
   * @param blockNumber Block Number against which to make the challenge.
   * @return true if user has enough power
   **/
  function isPropositionPowerEnough(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool);

  /**
   * @dev Returns the minimum Proposition Power needed to create a proposition.
   * @param governance Governance Contract
   * @param blockNumber Blocknumber at which to evaluate
   * @return minimum Proposition Power needed
   **/
  function getMinimumPropositionPowerNeeded(IAaveGovernanceV2 governance, uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns whether a proposal passed or not
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isProposalPassed(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has reached quorum, ie has enough FOR-voting-power
   * Here quorum is not to understand as number of votes reached, but number of for-votes reached
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return voting power needed for a proposal to pass
   **/
  function isQuorumValid(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
   * FOR VOTES - AGAINST VOTES > VOTE_DIFFERENTIAL * voting supply
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return true if enough For-Votes
   **/
  function isVoteDifferentialValid(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool);

  /**
   * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
   * @param votingSupply Total number of oustanding voting tokens
   * @return voting power needed for a proposal to pass
   **/
  function getMinimumVotingPowerNeeded(uint256 votingSupply) external view returns (uint256);

  /**
   * @dev Get proposition threshold constant value
   * @return the proposition threshold value (100 <=> 1%)
   **/
  function PROPOSITION_THRESHOLD() external view returns (uint256);

  /**
   * @dev Get voting duration constant value
   * @return the voting duration value in blocks
   **/
  function VOTING_DURATION() external view returns (uint256);

  /**
   * @dev Get the vote differential threshold constant value
   * to compare with % of for votes/total supply - % of against votes/total supply
   * @return the vote differential threshold value (100 <=> 1%)
   **/
  function VOTE_DIFFERENTIAL() external view returns (uint256);

  /**
   * @dev Get quorum threshold constant value
   * to compare with % of for votes/total supply
   * @return the quorum threshold value (100 <=> 1%)
   **/
  function MINIMUM_QUORUM() external view returns (uint256);

  /**
   * @dev precision helper: 100% = 10000
   * @return one hundred percents with our chosen precision
   **/
  function ONE_HUNDRED_WITH_PRECISION() external view returns (uint256);
}
