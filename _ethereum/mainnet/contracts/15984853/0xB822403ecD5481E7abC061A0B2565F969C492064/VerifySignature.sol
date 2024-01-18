// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library VerifySignature {
    function _getMessageHash(
        address account,
        uint256[] memory tokenIds
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, tokenIds));
    }

    function _getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function _verify(
        address signer,
        address account,
        uint256[] memory tokenIds,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = _getMessageHash(account, tokenIds);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        return _recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}