// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)
// Trimmed down to our specific use for Kingdom.so

pragma solidity ^0.8.0;

library ECDSA {
  error InvalidSignature();
  error InvalidSignatureLength();
  error InvalidSignatureS();
  error InvalidSignatureV();

  function _throwError(bytes4 error) private pure {
    if (uint32(error) == 0) return;
    assembly {
      mstore(0x00, error)
      revert(0x00, 0x04)
    }
  }

  function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, bytes4) {
    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
      return tryRecover(hash, v, r, s);
    } else if (signature.length == 64) {
      bytes32 r;
      bytes32 vs;
      assembly {
        r := mload(add(signature, 0x20))
        vs := mload(add(signature, 0x40))
      }
      return tryRecover(hash, r, vs);
    } else {
      return (address(0), InvalidSignatureLength.selector);
    }
  }

  function tryRecover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address, bytes4) {
    bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    uint8 v = uint8((uint256(vs) >> 255) + 27);
    return tryRecover(hash, v, r, s);
  }

  function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address, bytes4) {
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return (address(0), InvalidSignatureS.selector);
    }
    if (v != 27 && v != 28) {
      return (address(0), InvalidSignatureV.selector);
    }

    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
      return (address(0), InvalidSignature.selector);
    }

    return (signer, bytes4(uint32(0)));
  }

  function recover(bytes32 hash, bytes calldata signature) internal pure returns (address) {
    (address recovered, bytes4 error) = tryRecover(hash, signature);
    _throwError(error);
    return recovered;
  }

  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}
