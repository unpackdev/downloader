// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Voucher.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
contract NifkeyEIP712 is EIP712 {
    string private constant SIGNING_DOMAIN = "Nifkey-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    /// @notice Verifies the signature for a given NFKVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFKs.
    /// @param voucher An NFTVoucher describing an unminted NFK.
    function verify(NFKVoucher calldata voucher)
        external
        view
        returns (address)
    {
        // Get the address of the signer
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFKVoucher(string twitterUsername,address redeemerAddress,uint numFollowers,uint twitterId,bool isVerified,uint createdAt,uint nonce,uint mintPrice)"
                    ),
                    keccak256(bytes(voucher.twitterUsername)),
                    voucher.redeemerAddress,
                    voucher.numFollowers,
                    voucher.twitterId,
                    voucher.isVerified,
                    voucher.createdAt,
                    voucher.nonce,
                    voucher.mintPrice
                )
            )
        );
        return ECDSA.recover(digest, voucher.signature);
    }
}
