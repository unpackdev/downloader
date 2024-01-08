// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFK using the redeem function.
struct NFKVoucher {
    /// @notice String of the Twitter handle. Must be unique - if another token with this handle already exists, the redeem function will revert.
    string twitterUsername;
    // @notice The public key of the redeemer
    address redeemerAddress;
    /// @notice The number of followers
    uint256 numFollowers;
    /// @notice twitter id as string
    uint256 twitterId;
    /// @notice If the user is verified
    bool isVerified;
    /// @notice Date the account was created (unix timestamp)
    uint256 createdAt;
    /// @notice the EIP-712 signature of all other fields in the NFKVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
    /// @notice Nonce to ensure that old vouchers cannot be reused
    uint256 nonce;
    /// @notice Price the minter must pay to mint a nifkey
    uint256 mintPrice;
}
