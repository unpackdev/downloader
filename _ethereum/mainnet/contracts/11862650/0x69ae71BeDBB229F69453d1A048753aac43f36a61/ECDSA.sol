// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library ECDSA {
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    if (signature.length != 65) {
      revert('ECDSA: invalid signature length');
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    require(
      uint256(s) <=
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "ECDSA: invalid signature 's' value"
    );
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), 'ECDSA: invalid signature');

    return signer;
  }

  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }
}
