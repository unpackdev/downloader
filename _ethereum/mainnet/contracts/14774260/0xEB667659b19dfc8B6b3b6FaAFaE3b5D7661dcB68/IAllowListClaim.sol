// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IAllowListClaim {
  /**
   * @notice Sent when the merkle root has been updated
   */
  event MerkleRootChanged(bytes32 indexed merkleRoot);

  /**
   * @notice Sent when the claim period has been updated
   */
  event ClaimPeriodChanged(uint256 indexed claimPeriodStart, uint256 indexed claimPeriodEnd);

  /**
   * @notice Returns the claim period start and end dates as block timestamps.
   */
  function claimPeriod() external view returns (uint256, uint256);

  /**
   * @notice Returns the merkle root for the allow list claim
   */
  function merkleRoot() external view returns (bytes32);

  /**
   * @notice Returns the number of tokens already claimed by the given address
   */
  function alreadyClaimed(address account) external view returns (uint256);
}
