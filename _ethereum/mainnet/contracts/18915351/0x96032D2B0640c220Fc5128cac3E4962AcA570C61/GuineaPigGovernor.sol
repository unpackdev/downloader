// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./GovernorCountingFractional.sol";
import "./IGovernor.sol";
import "./GovernorVotes.sol";
import {GovernorTimelockControl} from
  "@openzeppelin/governance/extensions/GovernorTimelockControl.sol";
import "./GovernorSettings.sol";
import {GovernorVotesQuorumFraction} from
  "@openzeppelin/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorPreventLateQuorum} from
  "@openzeppelin/governance/extensions/GovernorPreventLateQuorum.sol";
import "./IVotes.sol";
import "./TimelockController.sol";

contract GuineaPigGovernor is
  GovernorCountingFractional,
  GovernorVotes,
  GovernorTimelockControl,
  GovernorSettings,
  GovernorVotesQuorumFraction,
  GovernorPreventLateQuorum
{
  /// @notice Human readable name of this Governor.
  string private constant GOVERNOR_NAME = "Guinea Pig DAO Governor v1";
  uint256 private constant BIP = 10_000;
  uint256 private constant INITIAL_QUORUM_PERCENTAGE_BIPS = 500; // 5% in bips

  constructor(
    IVotes _token,
    uint256 _initialVotingDelay,
    uint256 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    TimelockController _timelock
  )
    GovernorVotes(_token)
    GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold)
    GovernorTimelockControl(_timelock)
    GovernorVotesQuorumFraction(INITIAL_QUORUM_PERCENTAGE_BIPS)
    GovernorPreventLateQuorum(10)
    Governor(GOVERNOR_NAME)
  {}

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (bool)
  {
    return GovernorTimelockControl.supportsInterface(interfaceId);
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function castVoteWithReasonAndParamsBySig(
    uint256 proposalId,
    uint8 support,
    string calldata reason,
    bytes memory params,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override(Governor, GovernorCountingFractional, IGovernor) returns (uint256) {
    return GovernorCountingFractional.castVoteWithReasonAndParamsBySig(
      proposalId, support, reason, params, v, r, s
    );
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function proposalThreshold()
    public
    view
    virtual
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return GovernorSettings.proposalThreshold();
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function state(uint256 proposalId)
    public
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return GovernorTimelockControl.state(proposalId);
  }

  function quorumDenominator() public pure override returns (uint256) {
    return BIP;
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function proposalDeadline(uint256 proposalId)
    public
    view
    virtual
    override(IGovernor, Governor, GovernorPreventLateQuorum)
    returns (uint256)
  {
    return GovernorPreventLateQuorum.proposalDeadline(proposalId);
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _castVote(
    uint256 proposalId,
    address account,
    uint8 support,
    string memory reason,
    bytes memory params
  ) internal virtual override(Governor, GovernorPreventLateQuorum) returns (uint256) {
    return GovernorPreventLateQuorum._castVote(proposalId, account, support, reason, params);
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal virtual override(Governor, GovernorTimelockControl) {
    return GovernorTimelockControl._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _executor()
    internal
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (address)
  {
    return GovernorTimelockControl._executor();
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal virtual override(Governor, GovernorTimelockControl) returns (uint256) {
    return GovernorTimelockControl._cancel(targets, values, calldatas, descriptionHash);
  }
}
