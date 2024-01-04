// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;


/*
    Handy contract for remembering already used nonces.
*/
contract Nonce {
    mapping(uint16 => bool) public nonce;

    event NonceUsed(uint16 _nonce);

    function nonceNotUsed(uint16 _nonce) public view returns(bool) {
        return !nonce[_nonce];
    }

    function rememberNonce(uint16 _nonce) internal {
        nonce[_nonce] = true;

        emit NonceUsed(_nonce);
    }
}
