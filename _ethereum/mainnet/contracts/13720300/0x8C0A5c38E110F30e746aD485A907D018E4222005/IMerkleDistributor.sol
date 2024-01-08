// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account);

    // This event is triggered whenever a call to #clawback succeeds
    event Clawback();

    // Claim the given amount of the token to self. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        bytes32[] calldata merkleProof
    )
        external;
    
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claimByGovernance(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external;

    // Clawback the given amount of the token to the given address.
    function clawback() external;

    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the amount of the token distributed by this contract.
    function amountToClaim() external view returns (uint256);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, address account) external view returns (bool);

    // Returns the unlock block timestamp
    function unlockTimestamp() external view returns (uint256);

    // Returns the clawback block timestamp
    function clawbackTimestamp() external view returns (uint256);

    // Verify the merkle proof.
    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    )
        external
        view
        returns (bool);
}