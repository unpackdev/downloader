//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";

library Signature {
  using ECDSA for bytes32;

  function getSigner(
    bytes32 messageHash,
    bytes memory _signature
  ) internal view returns (address) {
    address signer = messageHash.toEthSignedMessageHash().recover(_signature);

    return signer;
  }
}
