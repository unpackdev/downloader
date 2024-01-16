// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AaveGovernanceV2.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title AutonomousProposalsForGovAdjustments
 * @author BGD Labs
 * @dev Autonomous proposal to simplify delegation, and creation of needed proposals for governance configuration adjustments.
 * - Introduces a method that on call, will create LongExecutor proposal, and afterwards will also create the EcosystemReserve proposal
 *   needed to use the ecosystem voting power to vote on the LongExecutor Proposal.
 *   With this, anyone can delegate Proposition Power to this contract, and when it reaches enough power, anyone will be able to call
 *   `createProposalsForGovAdjustments` method to create the two proposals.
 * - `createProposalsForGovAdjustments` can only be called once, while proposals are not created. This is so proposals do not
 *   keep being created, as the contract could maintain the proposition power, while delegators do not withdraw their delegation
 * - `createProposalsForGovAdjustments` can only be called after specified date. This is to ensure that there is time to amass
 *   enough proposition power into the contract, and that users have time to prepare for the vote.
 * - The payloads used will be:
 *   - NEW_LONG_EXECUTOR_PAYLOAD: src/contracts/ProposalPayloadNewLongExecutor.sol
 *   - ECOSYSTEM_RESERVE_WITH_VOTING_PAYLOAD: src/contracts/ProposalPayloadAaveEcosystemReserveWithVoting.sol
 */
contract AutonomousProposalsForGovAdjustments {
  using SafeERC20 for IERC20;

  uint256 public constant GRACE_PERIOD = 5 days;

  address public immutable NEW_LONG_EXECUTOR_PAYLOAD;
  bytes32 public immutable LVL2_IPFS_HASH;

  address public immutable ECOSYSTEM_RESERVE_WITH_VOTING_PAYLOAD;
  bytes32 public immutable RESERVE_ECOSYSTEM_IPFS_HASH;

  uint256 public immutable CREATION_TIMESTAMP;

  uint256 public newLongExecutorProposalId;
  uint256 public ecosystemReserveProposalId;

  event ProposalsCreated(
    address executor,
    uint256 newLongExecutorProposalId,
    uint256 ecosystemReserveProposalId,
    address newLongExecutorPayload,
    bytes32 lvl2IpfsHash,
    address ecosystemReserveWithVotingPayload,
    bytes32 reserveEcosystemIpfsHash
  );

  constructor (address newLongExecutorPayload, address ecosystemReserveWithVotingPayload, bytes32 lvl2IpfsHash, bytes32 reserveEcosystemIpfsHash, uint256 creationTimestamp) {
    require(newLongExecutorPayload != address(0), "NEW_LONG_EXECUTOR_PAYLOAD_ADDRESS_0");
    require(lvl2IpfsHash != bytes32(0), "NEW_LONG_EXECUTOR_PAYLOAD_IPFS_HASH_BYTES32_0");
    require(ecosystemReserveWithVotingPayload != address(0), "ECOSYSTEM_RESERVE_PAYLOAD_ADDRESS_0");
    require(reserveEcosystemIpfsHash != bytes32(0), "ECOSYSTEM_RESERVE_PAYLOAD_IPFS_HASH_BYTES32_0");
    require(creationTimestamp > block.timestamp, 'CREATION_TIMESTAMP_TO_EARLY');

    NEW_LONG_EXECUTOR_PAYLOAD = newLongExecutorPayload;
    LVL2_IPFS_HASH = lvl2IpfsHash;
    ECOSYSTEM_RESERVE_WITH_VOTING_PAYLOAD = ecosystemReserveWithVotingPayload;
    RESERVE_ECOSYSTEM_IPFS_HASH = reserveEcosystemIpfsHash;
    CREATION_TIMESTAMP = creationTimestamp;
  }

  /// @dev creates the necessary proposals for the governance parameter adjustments
  function createProposalsForGovAdjustments() external {
    require(newLongExecutorProposalId == 0 && ecosystemReserveProposalId == 0, 'PROPOSALS_ALREADY_CREATED');
    require(block.timestamp > CREATION_TIMESTAMP, 'CREATION_TIMESTAMP_NOT_YET_REACHED');
    require(block.timestamp < CREATION_TIMESTAMP + GRACE_PERIOD, 'TIMESTAMP_BIGGER_THAN_GRACE_PERIOD');

    newLongExecutorProposalId = _createLvl2Proposal(NEW_LONG_EXECUTOR_PAYLOAD, LVL2_IPFS_HASH);

    ecosystemReserveProposalId = _createEcosystemReserveProposal(ECOSYSTEM_RESERVE_WITH_VOTING_PAYLOAD, RESERVE_ECOSYSTEM_IPFS_HASH, newLongExecutorProposalId);

    emit ProposalsCreated(msg.sender, newLongExecutorProposalId, ecosystemReserveProposalId, NEW_LONG_EXECUTOR_PAYLOAD, LVL2_IPFS_HASH, ECOSYSTEM_RESERVE_WITH_VOTING_PAYLOAD, RESERVE_ECOSYSTEM_IPFS_HASH);
  }


  /// @dev method to vote on the governance parameters adjustment proposals, in case there is some
  /// voting power delegation by error
  function voteOnGovAdjustmentsProposal() external {
    require(newLongExecutorProposalId != 0 && ecosystemReserveProposalId != 0, 'PROPOSALS_NOT_CREATED');
    AaveGovernanceV2.GOV.submitVote(newLongExecutorProposalId, true);
    AaveGovernanceV2.GOV.submitVote(ecosystemReserveProposalId, true);
  }

  function emergencyTokenTransfer(
    address erc20Token,
    address to,
    uint256 amount
  ) external {
    require(msg.sender == AaveGovernanceV2.SHORT_EXECUTOR, 'CALLER_NOT_EXECUTOR');
    IERC20(erc20Token).safeTransfer(to, amount);
  }

  function _createLvl2Proposal(address payload, bytes32 ipfsHash) internal returns (uint256) {
    address[] memory targets = new address[](1);
    targets[0] = payload;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute()';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = '';
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    return AaveGovernanceV2.GOV.create(
      IExecutorWithTimelock(AaveGovernanceV2.LONG_EXECUTOR),
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      ipfsHash
    );
  }

  function _createEcosystemReserveProposal(address payload, bytes32 ipfsHash, uint256 proposalId) internal returns (uint256) {
    address[] memory targets = new address[](1);
    targets[0] = payload;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    string[] memory signatures = new string[](1);
    signatures[0] = 'execute(uint256)';
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encode(proposalId);
    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = true;

    return AaveGovernanceV2.GOV.create(
      IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR),
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      ipfsHash
    );
  }
}