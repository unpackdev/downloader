// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Verify {

    function verifyMessage(bytes32 hashedMessage, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        return signer;
    }

}