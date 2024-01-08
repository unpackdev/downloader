// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibBid.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

/// @title A validator for bids
/// @notice The validation will be called before accepting a bid
abstract contract BidValidator is EIP712 {
    constructor() EIP712("1Kind Exchange", "1") {}

    /// @param userBid Struct with bid properties
    /// @param signature Signature to decode and compare
    function validateBid(LibBid.Bid memory userBid, bytes memory signature)
        internal
        view
    {
        bytes32 bidHash = LibBid.bidHash(userBid);
        bytes32 digest = _hashTypedDataV4(bidHash);
        address signer = ECDSA.recover(digest, signature);

        require(
            signer == userBid.userWallet,
            "BidValidator: userBid signature verification error"
        );
    }
}
