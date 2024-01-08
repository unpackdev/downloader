// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @title A set of helper functions to verify signatures, to be used in the ClaimsRegistry
/// @author Miguel Palhas <miguel@subvisual.co>
contract Verifier {

  /// @notice Verifies that the given signature matches the provided data, and
  ///   was signed by the provided issuer. Assumes data was signed using the
  ///   Ethereum prefix to protect against unkonwingly signing transactions
  /// @param hash The data to verify
  /// @param sig The signature of the data
  /// @param signer The expected signer of the data
  /// @return `true` if `signer` and `hash` match `sig`
  function verifyWithPrefix(bytes32 hash, bytes calldata sig, address signer) public pure returns (bool) {
    return verify(addPrefix(hash), sig, signer);
  }

  /// @notice Recovers the signer of the given signature and data. Assumes data
  ///  was signed using the Ethereum prefix to protect against unknowingly signing
  ///  transaction.s
  /// @param hash The data to verify
  /// @param sig The signature of the data
  /// @return The address recovered by checking the signature against the data
  function recoverWithPrefix(bytes32 hash, bytes calldata sig) public pure returns (address) {
    return recover(addPrefix(hash), sig);
  }

  function verify(bytes32 hash, bytes calldata sig, address signer) internal pure returns (bool) {
    return recover(hash, sig) == signer;
  }

  function recover(bytes32 hash, bytes calldata _sig) internal pure returns (address) {
    bytes memory sig = _sig;
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return address(0);
    }

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := and(mload(add(sig, 65)), 255)
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return address(0);
    }

    return ecrecover(hash, v, r, s);
  }

  function addPrefix(bytes32 hash) private pure returns (bytes32) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";

    return keccak256(abi.encodePacked(prefix, hash));
  }
}
