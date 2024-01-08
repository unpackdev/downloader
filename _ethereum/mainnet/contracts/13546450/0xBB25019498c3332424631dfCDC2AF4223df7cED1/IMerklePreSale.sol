// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to purchase a token if they exist in a merkle root.
interface IMerklePreSale {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns true if the index has been marked purchased.
    function isPurchased(uint256 groupId, uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function purchase(uint256 groupId, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external payable;

    // This event is triggered whenever a call to #purchase succeeds.
    event Purchased(uint256 index, address account, uint256 amount);
}
