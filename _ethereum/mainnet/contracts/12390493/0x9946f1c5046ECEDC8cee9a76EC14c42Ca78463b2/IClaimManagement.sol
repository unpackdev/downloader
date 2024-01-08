// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ClaimManagement contract interface. See {ClaimManagement}.
 * @author Alan + crypto-pumpkin
 */
interface IClaimManagement {
  event ClaimUpdate(address indexed coverPool, ClaimState state, uint256 nonce, uint256 index);

  enum ClaimState { Filed, ForceFiled, Validated, Invalidated, Accepted, Denied }
  struct Claim {
    address filedBy; // Address of user who filed claim
    address decidedBy; // Address of the CVC who decided claim
    uint48 filedTimestamp; // Timestamp of submitted claim
    uint48 incidentTimestamp; // Timestamp of the incident the claim is filed for
    uint48 decidedTimestamp; // Timestamp when claim outcome is decided
    string description;
    ClaimState state; // Current state of claim
    uint256 feePaid; // Fee paid to file the claim
    bytes32[] payoutRiskList;
    uint256[] payoutRates; // Numerators of percent to payout
  }

  function getCoverPoolClaims(address _coverPool, uint256 _nonce, uint256 _index) external view returns (Claim memory);
  function getAllClaimsByState(address _coverPool, uint256 _nonce, ClaimState _state) external view returns (Claim[] memory);
  function getAllClaimsByNonce(address _coverPool, uint256 _nonce) external view returns (Claim[] memory);
  function hasPendingClaim(address _coverPool, uint256 _nonce) external view returns (bool);

  function fileClaim(
    string calldata _coverPoolName,
    bytes32[] calldata _exploitRisks,
    uint48 _incidentTimestamp,
    string calldata _description,
    bool _isForceFile
  ) external;
  
  // @dev Only callable by dev when auditor is voting
  function validateClaim(address _coverPool, uint256 _nonce, uint256 _index, bool _claimIsValid) external;

  // @dev Only callable by CVC
  function decideClaim(
    address _coverPool,
    uint256 _nonce,
    uint256 _index,
    uint48 _incidentTimestamp,
    bool _claimIsAccepted,
    bytes32[] calldata _exploitRisks,
    uint256[] calldata _payoutRates
  ) external;
 }