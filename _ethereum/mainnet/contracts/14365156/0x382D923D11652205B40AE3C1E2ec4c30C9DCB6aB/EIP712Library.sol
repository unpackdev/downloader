// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

abstract contract EIP712Library {

    struct TxFee {
        address token;
        bytes approvalData;
    }

    string public constant name = 'Plasma Gas Station';
    string public constant version = '1';
    mapping(address => uint256) public nonces;

    function getNonce(address from) external view returns (uint256) {
        return nonces[from];
    }

    function _splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "Signature invalid length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature invalid v byte");
    }
}
