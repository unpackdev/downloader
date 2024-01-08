// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // Update merkleRoot.
    function updateRoot(bytes32 newMerkleRoot) external;

    // Set admin permission to user.
    function setAdminPermission(address _user, bool _permission) external;

    // Transfer contract's ownership to user.
    function transferOwnership(address newOwner) external;
}
