// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibBid.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

/**
 * @dev EIP712 based contract module which validates a Bid.
 * The signer is {ESCROW_WALLET} and checks for integrity of
 * the bid. {bid} is struct defined in LibBid.
 *
 */
abstract contract BidValidator is EIP712 {
    constructor() EIP712("WedreamEscrow", "1") {}

    // Wallet that signs our bides
    address public ESCROW_WALLET;

    /**
     * @dev Validates if {bid} was signed by {ESCROW_WALLET} and created {signature}.
     *
     * @param bid Struct with bid properties
     * @param signature Signature to decode and compare
     */
    function validateBid(LibBid.Bid memory bid, bytes memory signature)
        internal
        view
    {
        bytes32 bidHash = LibBid.bidHash(bid);
        bytes32 digest = _hashTypedDataV4(bidHash);
        address signer = ECDSA.recover(digest, signature);

        require(
            signer == ESCROW_WALLET,
            "BidValidator: Bid signature verification error"
        );
    }
}
