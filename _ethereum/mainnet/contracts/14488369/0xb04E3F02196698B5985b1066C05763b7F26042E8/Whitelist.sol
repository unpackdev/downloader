 // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


abstract contract Whitelist {

    address internal _signer;


    function _getMessageHash(address _to, bool _believer) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _believer));
    }


    function _getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }


    function _verify(address _to, bool _believer, bytes memory _signature) internal view returns (bool) {
        bytes32 messageHash = _getMessageHash(_to, _believer);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        return _recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }


    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }


    function _splitSignature(bytes memory _signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_signature.length == 65, "invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}