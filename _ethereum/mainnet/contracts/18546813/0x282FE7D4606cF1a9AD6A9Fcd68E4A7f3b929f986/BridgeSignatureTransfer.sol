// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ECDSA.sol";
import "./draft-EIP712.sol";

import "./BridgeTransfer.sol";
import "./BridgeRoles.sol";
import "./BridgeSignatures.sol";

abstract contract BridgeSignatureTransfer is BridgeTransfer, BridgeSignatures {
    bytes32 public constant TELEPORT_TYPEHASH =
        keccak256("Teleport(address from,uint256 amount,uint256 nonce,uint256 deadline)");

    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address to,uint256 amount,uint256 otherChainNonce,uint256 deadline)");

    function _teleportSig(address from, uint256 amount, uint256 deadline, bytes32 r, bytes32 s, uint8 v) internal {
        require(_checkDeadline(deadline), "Bridge: Signature expired");
        bytes32 structHash = keccak256(abi.encode(TELEPORT_TYPEHASH, from, amount, nonce(), deadline));

        bytes32 digest = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(digest, v, r, s);

        require(signer == from, "Bridge: Invalid signature");

        _teleport(from, address(this), amount);
    }

    /**
     * @dev Claims tokens from the bridge contract.
     * @param to The address of the user who will receive the tokens.
     * @param amount The amount of tokens to claim.
     * @param otherChainNonce The nonce of the teleport on the other chain.
     * @param signatures The signatures of the backend signers.
     */
    function _claimSig(
        address to,
        uint256 amount,
        uint256 otherChainNonce,
        SignatureWithDeadline[] calldata signatures
    ) internal {
        bytes32[] memory digests = new bytes32[](signatures.length);

        for (uint256 id = 0; id < signatures.length; id++) {
            digests[id] = _getClaimTypehash(to, amount, otherChainNonce, signatures[id].deadline);
        }

        _checkSignatures(digests, signatures);

        _claim(to, amount, otherChainNonce);
    }

    /**
     * @dev Gets typehash of the claim request.
     * @param to The address of the user who will receive the tokens.
     * @param amount The amount of tokens to claim.
     * @param nonce The nonce of the claim.
     * @param deadline The deadline of the signature.
     */
    function _getClaimTypehash(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, to, amount, nonce, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        return digest;
    }
}
