// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// handles the signed messages
contract SignedMessages{
    mapping(uint256 => bool) internal nonces;
    mapping(address => bool) internal issuers;

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function consumePass(bytes32 message, bytes memory sig, uint256 nonce) internal returns(bool){
        // check the nonce first
        if (nonces[nonce]) {
            return false;
        }
        // check the issuer
        if (!issuers[recoverSigner(message, sig)]) {
            return false;
        }
        // consume the nonce if it is safe
        nonces[nonce] = true;
        return true;
    }

    function validateNonce(uint256 _nonce) public view returns(bool){
        return nonces[_nonce];
    }

    function setIssuer(address issuer, bool status) internal{
        issuers[issuer] = status;
    }

    function getIssuerStatus(address issuer) public view returns(bool){
        return issuers[issuer];
    }

    function recoverSigner(bytes32 _message, bytes memory sig) internal pure returns(address){
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(_message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns(uint8, bytes32, bytes32){
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r:= mload(add(sig, 32))
            // second 32 bytes
            s:= mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v:= byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

}