// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract SignedMessage {
    function getMessageHash(address _tokenContract, uint256 _tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenContract, _tokenId, address(this)));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function getSigner(
        address _tokenContract,
        uint256 _tokenId,
        bytes memory signature
    ) public view returns (address) {
        bytes32 messageHash = getMessageHash(_tokenContract, _tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
