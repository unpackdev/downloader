// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import "./IERC20.sol";

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns Terms and Conditions for claiming Ally tokens.
    function termsAndConditions() external view returns (string memory);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Returns true if the index has been marked T&Cs approved.
    function isAgreedToTerms(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid or T&Cs not approved yet.
    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external;
    // Approves T&Cs
    function consentAndAgreeToTerms(uint256 index, uint256 amount, bytes32 terms, bytes32[] calldata merkleProof) external;
    // Returns hash of user address and T&C
    function termsHash(address account) external view returns (bytes32);
    // Owner may withdraw liquidity from this contract to recover errant tokens or cause an emergency stop.
    function emergencyWithdraw(IERC20 _token, uint256 amount, address to) external;

    // This event is triggered whenever a call to #approveTerms succeeds.
    event AgreedToTerms(uint256 index, address account, uint256 amount, bytes32 terms);
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
    // This event is triggered whenever an emergency withdraw succeeds.
    event EmergencyWithdrawal(IERC20 _token, uint256 amount, address to);
}