// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IGovernanceCore.sol";
import "./IGovernanceChainRobotKeeper.sol";
import "./Ownable.sol";

/**
 * @title GovernanceChainRobotKeeper
 * @author BGD Labs
 * @notice Contract to perform automation on governance contract for goveranance v3.
 * @dev Aave chainlink automation-keeper-compatible contract to:
 *      - check if the proposal state could be moved to executed, cancelled or if voting could be activated.
 *      - move the proposal to executed/cancelled or activates voting if all the conditions are met.
 */
contract GovernanceChainRobotKeeper is Ownable, IGovernanceChainRobotKeeper {
  mapping(uint256 => bool) internal _disabledProposals;

  /// @inheritdoc IGovernanceChainRobotKeeper
  address public immutable GOVERNANCE;

  /**
   * @inheritdoc IGovernanceChainRobotKeeper
   * @dev maximum number of actions that can be performed by the keeper in one performUpkeep.
   *      we only perform a max of 5 actions in one performUpkeep as the gas consumption would be quite high otherwise.
   */
  uint256 public constant MAX_ACTIONS = 5;

  /**
   * @inheritdoc IGovernanceChainRobotKeeper
   * @dev maximum number of proposals to check before the latest proposal if an action could be performed upon.
   *      from the last proposal we check 20 more proposals to be very sure that no proposal is being unchecked.
   */
  uint256 public constant MAX_SKIP = 20;

  error NoActionCanBePerformed();

  /**
   * @param governance address of the governance contract.
   */
  constructor(address governance) {
    GOVERNANCE = governance;
  }

  /**
   * @inheritdoc AutomationCompatibleInterface
   * @dev run off-chain, checks if proposals should be moved to executed, cancelled state or if voting could be activated
   */
  function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
    ActionWithId[] memory actionsWithIds = new ActionWithId[](MAX_ACTIONS);

    uint256 index = IGovernanceCore(GOVERNANCE).getProposalsCount();
    uint256 skipCount = 0;
    uint256 actionsCount = 0;

    // loops from the last/latest proposalId until MAX_SKIP iterations. resets skipCount and checks more MAX_SKIP number
    // of proposals if any action could be performed. we only check proposals until MAX_SKIP iterations from the last/latest
    // proposalId or proposals where any action could be performed, and proposals before that will be not be checked by the keeper.
    while (index != 0 && skipCount <= MAX_SKIP && actionsCount < MAX_ACTIONS) {
      uint256 proposalId = index - 1;

      if (!isDisabled(proposalId)) {
        IGovernanceCore.Proposal memory proposal = IGovernanceCore(GOVERNANCE).getProposal(
          proposalId
        );

        if (_isProposalInFinalState(proposal.state)) {
          skipCount++;
        } else {
          if (_canProposalBeCancelled(proposal)) {
            actionsWithIds[actionsCount].id = proposalId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformCancel;
            actionsCount++;
          } else if (_canVotingBeActivated(proposal)) {
            actionsWithIds[actionsCount].id = proposalId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformActivateVoting;
            actionsCount++;
          } else if (_canProposalBeExecuted(proposal)) {
            actionsWithIds[actionsCount].id = proposalId;
            actionsWithIds[actionsCount].action = ProposalAction.PerformExecute;
            actionsCount++;
          }
          skipCount = 0;
        }
      }

      index--;
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
   * @dev executes cancel, execute, activate voting action on the governance contract
   * @param performData array of proposal ids, array of actions whether to execute, cancel or activate voting
   */
  function performUpkeep(bytes calldata performData) external override {
    ActionWithId[] memory actionsWithIds = abi.decode(performData, (ActionWithId[]));
    bool isActionPerformed;

    // executes action on proposalIds in order from first to last
    for (uint256 i = actionsWithIds.length; i > 0; i--) {
      uint256 proposalId = actionsWithIds[i - 1].id;
      ProposalAction action = actionsWithIds[i - 1].action;

      IGovernanceCore.Proposal memory proposal = IGovernanceCore(GOVERNANCE).getProposal(
        proposalId
      );

      if (action == ProposalAction.PerformCancel && _canProposalBeCancelled(proposal)) {
        IGovernanceCore(GOVERNANCE).cancelProposal(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      } else if (
        action == ProposalAction.PerformActivateVoting && _canVotingBeActivated(proposal)
      ) {
        IGovernanceCore(GOVERNANCE).activateVoting(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      } else if (action == ProposalAction.PerformExecute && _canProposalBeExecuted(proposal)) {
        IGovernanceCore(GOVERNANCE).executeProposal(proposalId);
        isActionPerformed = true;
        emit ActionSucceeded(proposalId, action);
      }
    }

    if (!isActionPerformed) revert NoActionCanBePerformed();
  }

  /// @inheritdoc IGovernanceChainRobotKeeper
  function isDisabled(uint256 id) public view returns (bool) {
    return _disabledProposals[id];
  }

  /// @inheritdoc IGovernanceChainRobotKeeper
  function toggleDisableAutomationById(uint256 id) external onlyOwner {
    _disabledProposals[id] = !_disabledProposals[id];
  }

  /**
   * @notice method to check if the proposal state is in final state.
   * @param proposalState the current state the proposal is in.
   * @return true if the proposal state is final state, false otherwise.
   */
  function _isProposalInFinalState(
    IGovernanceCore.State proposalState
  ) internal pure returns (bool) {
    return (uint8(proposalState) > uint8(IGovernanceCore.State.Queued));
  }

  /**
   * @notice method to check if voting can be activated for the proposal.
   * @param proposal the proposal to check for which voting can be activated.
   * @return true if for the proposal voting can be activated, false otherwise.
   */
  function _canVotingBeActivated(
    IGovernanceCore.Proposal memory proposal
  ) internal view returns (bool) {
    IGovernanceCore.VotingConfig memory votingConfig = IGovernanceCore(GOVERNANCE).getVotingConfig(
      proposal.accessLevel
    );
    return (block.timestamp - proposal.creationTime > votingConfig.coolDownBeforeVotingStart &&
      proposal.state == IGovernanceCore.State.Created);
  }

  /**
   * @notice method to check if proposal could be executed.
   * @param proposal the proposal to check if it can be executed.
   * @return true if the proposal could be executed, false otherwise.
   */
  function _canProposalBeExecuted(
    IGovernanceCore.Proposal memory proposal
  ) internal view returns (bool) {
    return (proposal.state == IGovernanceCore.State.Queued &&
      block.timestamp >= proposal.queuingTime + IGovernanceCore(GOVERNANCE).COOLDOWN_PERIOD());
  }

  /**
   * @notice method to check if the proposal could be cancelled
   * @param proposal the proposal to check if it can be cancelled.
   * @return true if the proposal could be cancelled, false otherwise.
   */
  function _canProposalBeCancelled(
    IGovernanceCore.Proposal memory proposal
  ) internal view returns (bool) {
    IGovernanceCore.VotingConfig memory votingConfig = IGovernanceCore(GOVERNANCE).getVotingConfig(
      proposal.accessLevel
    );
    uint256 propositionPower = IGovernanceCore(GOVERNANCE)
      .getPowerStrategy()
      .getFullPropositionPower(proposal.creator);
    return (proposal.state != IGovernanceCore.State.Null &&
      uint8(proposal.state) < uint8(IGovernanceCore.State.Executed) &&
      propositionPower <
      votingConfig.minPropositionPower * IGovernanceCore(GOVERNANCE).PRECISION_DIVIDER());
  }
}
