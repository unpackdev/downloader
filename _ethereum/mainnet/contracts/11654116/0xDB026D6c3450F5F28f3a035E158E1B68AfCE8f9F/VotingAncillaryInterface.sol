// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";

abstract contract VotingAncillaryInterface {
  struct PendingRequestAncillary {
    bytes32 identifier;
    uint256 time;
    bytes ancillaryData;
  }

  struct CommitmentAncillary {
    bytes32 identifier;
    uint256 time;
    bytes ancillaryData;
    bytes32 hash;
    bytes encryptedVote;
  }

  struct RevealAncillary {
    bytes32 identifier;
    uint256 time;
    int256 price;
    bytes ancillaryData;
    int256 salt;
  }

  enum Phase {Commit, Reveal, NUM_PHASES_PLACEHOLDER}

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash
  ) public virtual;

  function batchCommit(CommitmentAncillary[] memory commits) public virtual;

  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash,
    bytes memory encryptedVote
  ) public virtual;

  function snapshotCurrentRound(bytes calldata signature) external virtual;

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    bytes memory ancillaryData,
    int256 salt
  ) public virtual;

  function batchReveal(RevealAncillary[] memory reveals) public virtual;

  function getPendingRequests()
    external
    view
    virtual
    returns (PendingRequestAncillary[] memory);

  function getVotePhase() external view virtual returns (Phase);

  function getCurrentRoundId() external view virtual returns (uint256);

  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequestAncillary[] memory toRetrieve
  ) public virtual returns (FixedPoint.Unsigned memory);

  function setMigrated(address newVotingAddress) external virtual;

  function setInflationRate(FixedPoint.Unsigned memory newInflationRate)
    public
    virtual;

  function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage)
    public
    virtual;

  function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout)
    public
    virtual;
}
