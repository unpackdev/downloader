// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Bech32.sol";
import "./Secp256k1.sol";

contract TerraClaimable {
    error InvalidSignatureLength();
    error InvalidSignature();
    error InvalidAddress();

    function canClaim(bytes memory _signature, bytes memory _compPubKey) public view returns (bool) {
        bytes32 hashedAddress = sha256(abi.encodePacked(msg.sender));

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        address recoveredAddress = ecrecover(hashedAddress, v, r, s);
        if (recoveredAddress == address(0)) revert InvalidSignature();

        bytes memory _pubKey = decompressPubKey(_compPubKey);

        address computedAddress = address(uint160(uint256(keccak256(_pubKey))));

        if (recoveredAddress != computedAddress) revert InvalidAddress();

        return true;
    }

    function convertToArray(bytes memory _data) internal pure returns (uint256[] memory output) {
        output = new uint256[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            output[i] = uint256(uint8(_data[i]));
        }
    }

    function addressFromPublicKey(bytes memory _compPubKey) public pure returns (string memory result) {
        bytes memory pubKeyHash = abi.encodePacked(ripemd160(abi.encodePacked(sha256(abi.encodePacked(_compPubKey)))));

        uint256[] memory pubKeyNumbers = convertToArray(pubKeyHash);
        uint256[] memory pubKey5BitBase = Bech32.convert(pubKeyNumbers, 8, 5);

        result = string.concat("terra1", string(Bech32.encode(convertToArray(bytes("terra")), pubKey5BitBase)));
    }

    function splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        if (_sig.length != 65) revert InvalidSignatureLength();

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function decompressPubKey(bytes memory _compPubKey) internal pure returns (bytes memory pubKey) {
        uint8 prefix;
        uint256 x;

        assembly {
            prefix := byte(0, mload(add(_compPubKey, 32)))
            x := mload(add(_compPubKey, 33))
        }

        uint256 y = EllipticCurve.deriveY(prefix, x);

        pubKey = bytes.concat(bytes32(x), bytes32(y));
    }
}
