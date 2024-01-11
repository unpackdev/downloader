// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./draft-EIP712.sol";
import "./SignatureChecker.sol";

/**
 * @title MarketTxValidatable
 * MarketTxValidatable - This contract manages the tx for market.
 */
abstract contract MarketTxValidatable is Context, EIP712 {
    using SignatureChecker for address;

    function _validateTx(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool, string memory) {
        if (signature.length == 0) {
            address sender = _msgSender();
            if (signer != sender) {
                return (
                    false,
                    "MarketTxValidatable: sender verification failed"
                );
            }
        } else {
            if (
                !signer.isValidSignatureNow(_hashTypedDataV4(hash), signature)
            ) {
                return (
                    false,
                    "MarketTxValidatable: signature verification failed"
                );
            }
        }
        return (true, "");
    }
}
