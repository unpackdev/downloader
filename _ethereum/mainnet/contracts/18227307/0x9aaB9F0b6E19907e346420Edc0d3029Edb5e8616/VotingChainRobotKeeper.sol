// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IRootsConsumer.sol";
import "./IVotingStrategy.sol";
import "./IVotingMachineWithProofs.sol";
import "./DataWarehouse.sol";
import "./IVotingChainRobotKeeper.sol";
import "./GovernanceV3Ethereum.sol";
import "./Ownable.sol";

/**
 * @title VotingChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on voting machine and data warehouse contract for goveranance v3.
 * @dev Aave chainlink automation-keeper-compatible contract to:
 *      - check if createVote, closeAndSendVote be called could be called for the proposal on voting machine or
 *        if roots needs to be submitted on the data warehouse.
 *      - Calls createVote and closeAndSendVote, submits roots if all the conditions are met.
 */
contract VotingChainRobotKeeper is Ownable, IVotingChainRobotKeeper {
  /// @inheritdoc IVotingChainRobotKeeper
  address public immutable VOTING_MACHINE;

  /// @inheritdoc IVotingChainRobotKeeper
  address public immutable VOTING_STRATEGY;

  /// @inheritdoc IVotingChainRobotKeeper
  address public immutable ROOTS_CONSUMER;

  /// @inheritdoc IVotingChainRobotKeeper
  address public immutable DATA_WAREHOUSE;

  mapping(uint256 => bool) internal _disabledProposals;
  mapping(bytes32 => bool) internal _rootsSubmitted;

  /**
   * @inheritdoc IVotingChainRobotKeeper
   * @dev maximum number of actions that can be performed by the keeper in one performUpkeep.
   *      we only perform a max of 5 actions in one performUpkeep as the gas consumption would be quite high otherwise.
   */
  uint256 public constant MAX_ACTIONS = 5;

  /**
   * @inheritdoc IVotingChainRobotKeeper
   * @dev size of the proposal list to fetch from last/latest to check if an action could be performed upon.
   *      we fetch the last 20 proposal and check to be very sure that no proposal is being unchecked.
   */
  uint256 public constant SIZE = 20;

  error NoActionCanBePerformed();

  /**
   * @param votingMachine address of the voting machine contract.
   * @param rootsConsumer address of the roots consumer contract to registers the roots.
   */
  constructor(
    address votingMachine,
    address rootsConsumer
  ) {
    VOTING_MACHINE = votingMachine;
    ROOTS_CONSUMER = rootsConsumer;
    VOTING_STRATEGY = address(IVotingMachineWithProofs(VOTING_MACHINE).VOTING_STRATEGY());
    DATA_WAREHOUSE = address(IVotingMachineWithProofs(VOTING_MACHINE).DATA_WAREHOUSE());
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if payload should be executed, createVote closeAndSendVote needs
   *      to be called or if roots needs to be submitted.
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    ActionWithId[] memory actionsWithIds = new ActionWithId[](MAX_ACTIONS);

    bool canVotingActionBePerformed;
    uint256 actionsCount;
    uint256 skip;

    // we fetch the proposal list from the last/latest proposalId till the SIZE, and check if any action could be performed.
    // in case any voting action can be performed, we fetch the proposal list again, starting from (latest proposalId - SIZE) till
    // the size and check again. we only check proposals from the last proposalId or (latest proposalId - SIZE) and so on till size if
    // any action could be performed and proposals beyond that will not be checked by the keeper.
    while (true) {
      (canVotingActionBePerformed, actionsCount, actionsWithIds) = _checkForVotingActions(
        skip,
        actionsCount,
        actionsWithIds
      );
      if (canVotingActionBePerformed) {
        skip += SIZE;
      } else {
        break;
      }
    }

    if (actionsCount > 0) {
      // we do not know the length in advance, so we init arrays with MAX_ACTIONS
      // and then squeeze the array using mstore
      assembly {
        mstore(actionsWithIds, actionsCount)
      }
      bytes memory performData = abi.encode(actionsWithIds);
      return (true, performData);
    }

    return (false, '');
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev executes submits root action by calling requestSubmitRoots on roots consumer, and createVote, closeAndSendVote action on the voting machine.
   * @param performData array of proposal ids, array of actions whether to executePayload, submit roots or createVote, closeAndSendVote.
   */
  function performUpkeep(bytes calldata performData) external override {
    ActionWithId[] memory actionsWithIds = abi.decode(performData, (ActionWithId[]));
    bool isActionPerformed;

    // executes action on proposalIds / roots consumer in order from first to last
    for (uint256 i = actionsWithIds.length; i > 0; i--) {
      uint256 proposalId = actionsWithIds[i - 1].id;
      ProposalAction action = actionsWithIds[i - 1].action;

      IVotingMachineWithProofs.ProposalState proposalState = IVotingMachineWithProofs(
        VOTING_MACHINE
      ).getProposalState(proposalId);

      IVotingMachineWithProofs.ProposalVoteConfiguration
        memory voteConfig = IVotingMachineWithProofs(VOTING_MACHINE).getProposalVoteConfiguration(
          proposalId
        );

      if (
        action == ProposalAction.PerformSubmitRoots &&
        !_rootsSubmitted[voteConfig.l1ProposalBlockHash] &&
        _canSubmitRoots(proposalState, voteConfig)
      ) {
        IRootsConsumer(ROOTS_CONSUMER).requestSubmitRoots(voteConfig.l1ProposalBlockHash);
        isActionPerformed = true;
        _rootsSubmitted[voteConfig.l1ProposalBlockHash] = true;
        emit ActionSucceeded(proposalId, action);
      } else if (
        action == ProposalAction.PerformCreateVote && _canCreateVote(proposalState, voteConfig)
      ) {
        IVotingMachineWithProofs(VOTING_MACHINE).startProposalVote(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      } else if (
        action == ProposalAction.PerformCloseAndSendVote && _canCloseAndSendVote(proposalState)
      ) {
        IVotingMachineWithProofs(VOTING_MACHINE).closeAndSendVote(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IVotingChainRobotKeeper
  function isDisabled(uint256 id) public view returns (bool) {
    return _disabledProposals[id];
  }

  /// @inheritdoc IVotingChainRobotKeeper
  function toggleDisableAutomationById(uint256 id) external onlyOwner {
    _disabledProposals[id] = !_disabledProposals[id];
  }

  /// @inheritdoc IVotingChainRobotKeeper
  function retrySubmitRoots(uint256 proposalId) external onlyOwner {
    IVotingMachineWithProofs.ProposalVoteConfiguration memory voteConfig = IVotingMachineWithProofs(
      VOTING_MACHINE
    ).getProposalVoteConfiguration(proposalId);
    _rootsSubmitted[voteConfig.l1ProposalBlockHash] = false;
  }

  /**
   * @notice method to check and return if any voting actions could be performed for proposals in the given range.
   * @param skip the number of proposals to skip from the last/latest.
   * @param actionsCount the current count of the number of voting actions that can be performed.
   * @param actionsWithIds the current list of objects containing the current proposals id and voting actions which can be performed.
   * @return true if any voting action could be performed for the proposals in the given range, false otherwise.
   * @return the updated count of the number of voting actions that can be performed.
   * @return the updated list of objects containing the current proposals id and voting actions which can be performed.
   */
  function _checkForVotingActions(
    uint256 skip,
    uint256 actionsCount,
    ActionWithId[] memory actionsWithIds
  ) internal view returns (bool, uint256, ActionWithId[] memory) {
    uint256[] memory proposalIds = IVotingMachineWithProofs(VOTING_MACHINE)
      .getProposalsVoteConfigurationIds(skip, SIZE);
    uint256 initialActionsCount = actionsCount;

    for (uint256 i = 0; i < proposalIds.length; i++) {
      if (!isDisabled(proposalIds[i])) {
        if (actionsCount > MAX_ACTIONS) break;

        IVotingMachineWithProofs.ProposalState proposalState = IVotingMachineWithProofs(
          VOTING_MACHINE
        ).getProposalState(proposalIds[i]);
        IVotingMachineWithProofs.ProposalVoteConfiguration
          memory voteConfig = IVotingMachineWithProofs(VOTING_MACHINE).getProposalVoteConfiguration(
            proposalIds[i]
          );

        if (_canSubmitRoots(proposalState, voteConfig)) {
          actionsWithIds[actionsCount].id = proposalIds[i];
          actionsWithIds[actionsCount].action = ProposalAction.PerformSubmitRoots;
          actionsCount++;
        } else if (_canCreateVote(proposalState, voteConfig)) {
          actionsWithIds[actionsCount].id = proposalIds[i];
          actionsWithIds[actionsCount].action = ProposalAction.PerformCreateVote;
          actionsCount++;
        } else if (_canCloseAndSendVote(proposalState)) {
          actionsWithIds[actionsCount].id = proposalIds[i];
          actionsWithIds[actionsCount].action = ProposalAction.PerformCloseAndSendVote;
          actionsCount++;
        }
      }
    }

    return (initialActionsCount != actionsCount, actionsCount, actionsWithIds);
  }

  /**
   * @notice method to check if roots can be submitted for the proposal in given state and vote configuration.
   * @param proposalState the current state the proposal is in.
   * @param voteConfig the vote configuration of the proposal passed from l1.
   * @return true if roots can be submitted, false otherwise.
   */
  function _canSubmitRoots(
    IVotingMachineWithProofs.ProposalState proposalState,
    IVotingMachineWithProofs.ProposalVoteConfiguration memory voteConfig
  ) internal view returns (bool) {
    return (proposalState == IVotingMachineWithProofs.ProposalState.NotCreated &&
      !_hasRequiredRoots(voteConfig.l1ProposalBlockHash) &&
      !_rootsSubmitted[voteConfig.l1ProposalBlockHash]);
  }

  /**
   * @notice method to check if create vote action can be performed for the proposal in given state and vote configuration.
   * @param proposalState the current state the proposal is in.
   * @param voteConfig the vote configuration of the proposal passed from l1.
   * @return true if create vote action can be performed, false otherwise.
   */
  function _canCreateVote(
    IVotingMachineWithProofs.ProposalState proposalState,
    IVotingMachineWithProofs.ProposalVoteConfiguration memory voteConfig
  ) internal view returns (bool) {
    return (proposalState == IVotingMachineWithProofs.ProposalState.NotCreated &&
      _hasRequiredRoots(voteConfig.l1ProposalBlockHash));
  }

  /**
   * @notice method to check if close and send vote action can be performed for the proposal in given state.
   * @param proposalState the current state the proposal is in.
   * @return true if close and send vote action can be performed, false otherwise.
   */
  function _canCloseAndSendVote(
    IVotingMachineWithProofs.ProposalState proposalState
  ) internal pure returns (bool) {
    return (proposalState == IVotingMachineWithProofs.ProposalState.Finished);
  }

  /**
   * @notice method to check if for a given blockhash roots have been registered for all the tokens.
   * @param snapshotBlockHash hash of the block to check from where the roots have been registered.
   * @return true if roots have been registered, false otherwise.
   */
  function _hasRequiredRoots(bytes32 snapshotBlockHash) internal view returns (bool) {
    bool hasRequiredRoots;
    try IVotingStrategy(VOTING_STRATEGY).hasRequiredRoots(snapshotBlockHash) {
      if (
        IDataWarehouse(DATA_WAREHOUSE).getStorageRoots(
          address(GovernanceV3Ethereum.GOVERNANCE),
          snapshotBlockHash
        ) != bytes32(0)
      ) {
        hasRequiredRoots = true;
      }
    } catch (bytes memory) {}

    return hasRequiredRoots;
  }
}
