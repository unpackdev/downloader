// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./MultiRole.sol";
import "./Withdrawable.sol";
import "./VotingAncillaryInterface.sol";
import "./FinderInterface.sol";
import "./Constants.sol";

contract DesignatedVoting is Withdrawable {
  enum Roles {Owner, Voter}

  FinderInterface private finder;

  constructor(
    address finderAddress,
    address ownerAddress,
    address voterAddress
  ) public {
    _createExclusiveRole(
      uint256(Roles.Owner),
      uint256(Roles.Owner),
      ownerAddress
    );
    _createExclusiveRole(
      uint256(Roles.Voter),
      uint256(Roles.Owner),
      voterAddress
    );
    _setWithdrawRole(uint256(Roles.Owner));

    finder = FinderInterface(finderAddress);
  }

  function commitVote(
    bytes32 identifier,
    uint256 time,
    bytes memory ancillaryData,
    bytes32 hash
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().commitVote(identifier, time, ancillaryData, hash);
  }

  function batchCommit(
    VotingAncillaryInterface.CommitmentAncillary[] calldata commits
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().batchCommit(commits);
  }

  function revealVote(
    bytes32 identifier,
    uint256 time,
    int256 price,
    bytes memory ancillaryData,
    int256 salt
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().revealVote(
      identifier,
      time,
      price,
      ancillaryData,
      salt
    );
  }

  function batchReveal(
    VotingAncillaryInterface.RevealAncillary[] calldata reveals
  ) external onlyRoleHolder(uint256(Roles.Voter)) {
    _getVotingAddress().batchReveal(reveals);
  }

  function retrieveRewards(
    uint256 roundId,
    VotingAncillaryInterface.PendingRequestAncillary[] memory toRetrieve
  )
    public
    onlyRoleHolder(uint256(Roles.Voter))
    returns (FixedPoint.Unsigned memory)
  {
    return
      _getVotingAddress().retrieveRewards(address(this), roundId, toRetrieve);
  }

  function _getVotingAddress() private view returns (VotingAncillaryInterface) {
    return
      VotingAncillaryInterface(
        finder.getImplementationAddress(OracleInterfaces.Oracle)
      );
  }
}
