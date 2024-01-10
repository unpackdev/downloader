// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract WhitelistVerifier {
    address private adminAddress;

    function _setAdminAddress(address _adminAddress) internal {
        adminAddress = _adminAddress;
    }

    modifier verifyWhitelist(
        address _to,
        uint _bucket,
        uint _nonce,
        bytes memory signature
    ) {
        bytes32 messageHash = getMessageHash(_to, _bucket, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(
            adminAddress == recoverSigner(ethSignedMessageHash, signature),
            "Message was not signed by admin"
        );
        _;
    }

    function getMessageHash(
        address _to,
        uint _bucket,
        uint _nonce
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _bucket, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
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
