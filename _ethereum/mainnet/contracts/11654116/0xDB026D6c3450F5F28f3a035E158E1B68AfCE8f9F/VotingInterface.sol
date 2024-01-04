// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./VotingAncillaryInterface.sol";

abstract contract VotingInterface {
  struct PendingRequest {
    bytes32 identifier;
    uint256 time;
  }

  struct Commitment {
    bytes32 identifier;
    uint256 time;
    bytes32 hash;
    bytes encryptedVote;
  }

  struct Reveal {
    bytes32 identifier;
    uint256 time;
    int256 price;
    int256 salt;
  }

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash
  ) external virtual;

  function batchCommit(Commitment[] memory commits) public virtual;

  function commitAndEmitEncryptedVote(
    bytes32 identifier,
    uint256 time,
    bytes32 hash,
    bytes memory encryptedVote
  ) public virtual;

  function snapshotCurrentRound(bytes calldata signature) external virtual;

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    int256 salt
  ) public virtual;

  function batchReveal(Reveal[] memory reveals) public virtual;

  function getPendingRequests()
    external
    view
    virtual
    returns (VotingAncillaryInterface.PendingRequestAncillary[] memory);

  function getVotePhase()
    external
    view
    virtual
    returns (VotingAncillaryInterface.Phase);

  function getCurrentRoundId() external view virtual returns (uint256);

  function retrieveRewards(
    address voterAddress,
    uint256 roundId,
    PendingRequest[] memory toRetrieve
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
