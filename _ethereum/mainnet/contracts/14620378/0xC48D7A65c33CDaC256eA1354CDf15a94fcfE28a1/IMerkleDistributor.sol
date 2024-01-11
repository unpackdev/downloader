// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the expiration time of the airdrop as unix timestamp (Seconds since unix epoch)
    function expireTimestamp() external view returns (uint256);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external;

    // Transfers the full token balance from the distributor contract to `target` address.
    function sweep(address target) external;
    // Transfers the full token balance from the distributor contract to owner of contract.
    function sweepToOwner() external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}