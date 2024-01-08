// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./ECDSA.sol";

contract EIP1271 {
  
  using ECDSA for bytes32;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  // bytes4 constant internal MAGICVALUE = 0x1626ba7e;

  /**
   * @dev Should return whether the signature provided is valid for the provided hash
   * @param hash      Hash of the data to be signed
   * @param signature Signature byte array associated with _hash
   *
   * MUST return the bytes4 magic value 0x1626ba7e when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */ 
  function isValidSignature(
    bytes32 hash, 
    bytes memory signature
  ) external view returns (bytes4 magicValue) {
      address signer = hash.recover(signature);
      // @audit see for any potential issues for using signer == tx.origin
      if (signer == tx.origin) {
        return 0x1626ba7e;
      } else {
        return 0xffffffff;
      }
    }
}