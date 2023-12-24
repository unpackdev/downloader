// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Signature {

    enum Type {
        EIP712,  //0
        EIP1271, //1
        ETHSIGN  //2
    }

    struct TypedSignature {
        Type signatureType;
        bytes signatureBytes;
    }

    struct MakerSignatures {
        TypedSignature signature;
        bool usingPermit2;
    }

    struct TakerPermitsInfo {
        bytes[] permitSignatures;
        bytes signatureBytesPermit2;
        uint48[] noncesPermit2;
        uint48 deadline;
    }

    function getRsv(bytes memory sig) internal pure returns (bytes32, bytes32, uint8){
        require(sig.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid sig value S");
        require(v == 27 || v == 28, "Invalid sig value V");
        return (r, s, v);
    }
}
