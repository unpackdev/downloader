// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMerkleAccessController {
  /// @notice Emitted when the contract owner updates the staking allowlist
  /// @param oldMerkleRoot The root of the old Staking allowlist merkle tree
  /// @param newMerkleRoot The root of a new Staking allowlist merkle tree
  event MerkleRootChanged(bytes32 oldMerkleRoot, bytes32 newMerkleRoot);

  /// @notice Validates if a community staker has access to the private staking pool
  /// @param staker The community staker's address
  /// @param proof Merkle proof for the community staker's allowlist
  /// @return true If the staker has access to the private staking pool
  function hasAccess(address staker, bytes32[] calldata proof) external view returns (bool);

  /// @notice This function is called to update the staking allowlist in a private staking pool
  /// @dev Only callable by the contract owner
  /// @param newMerkleRoot Merkle Tree root, used to prove access for community stakers
  /// will be required at opening but can be removed at any time by the owner when
  /// staking access will be granted to the public.
  function setMerkleRoot(bytes32 newMerkleRoot) external;

  /// @notice This function returns the current root of the Staking allowlist merkle tree
  /// @return The current root of the Staking allowlist merkle tree
  function getMerkleRoot() external view returns (bytes32);
}
