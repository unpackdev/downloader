// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreSignatureVerificationV1.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./DefinitiveErrors.sol";

/*
    To encode a bytes32 messageHash for signature verification):
        keccak256(abi.encodePacked(...))
*/
abstract contract CoreSignatureVerification is ICoreSignatureVerificationV1, ContextUpgradeable, OwnableUpgradeable {
    address public _signatureVerificationSigner;

    function __CoreSignatureVerification_init(address signer) internal onlyInitializing {
        __Context_init();
        __Ownable_init();
        __CoreSignatureVerification_init_unchained(signer);
    }

    function __CoreSignatureVerification_init_unchained(address signer) internal onlyInitializing {
        _signatureVerificationSigner = signer;
    }

    function _verifySignature(bytes32 messageHash, bytes memory signature) internal view {
        if (_signatureVerificationSigner == address(0)) {
            revert NoSignatureVerificationSignerSet();
        }

        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        if (!_verifySignedBy(_signatureVerificationSigner, ethSignedMessageHash, signature)) {
            revert InvalidSignature();
        }
    }

    /* cSpell:disable */
    function _getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
            Signature is produced by signing a keccak256 hash with the following format:
            "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /* cSpell:enable */

    function _verifySignedBy(
        address signer,
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) private pure returns (bool) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s) == signer;
    }

    // https://solidity-by-example.org/signature
    function _splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) {
            revert InvalidSignatureLength();
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function setSignatureVerificationSigner(address signer) external onlyOwner {
        _signatureVerificationSigner = signer;
        emit SignatureVerificationSignerUpdate(signer, _msgSender());
    }
}
