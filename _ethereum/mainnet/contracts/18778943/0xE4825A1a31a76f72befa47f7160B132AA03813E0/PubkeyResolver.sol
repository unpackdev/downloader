// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ResolverBase.sol";
import "./IPubkeyResolver.sol";

abstract contract PubkeyResolver is IPubkeyResolver, ResolverBase {
  struct PublicKey {
    bytes32 x;
    bytes32 y;
  }

  mapping(uint64 => mapping(bytes32 => PublicKey)) versionable_pubkeys;

  function setPubkey(
    bytes32 node,
    bytes32 x,
    bytes32 y
  ) external virtual authorised(node) {
    versionable_pubkeys[recordVersions[node]][node] = PublicKey(x, y);
    emit PubkeyChanged(node, x, y);
  }

  function pubkey(
    bytes32 node
  ) external view virtual override returns (bytes32 x, bytes32 y) {
    uint64 currentRecordVersion = recordVersions[node];
    return (
      versionable_pubkeys[currentRecordVersion][node].x,
      versionable_pubkeys[currentRecordVersion][node].y
    );
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view virtual override returns (bool) {
    return
      interfaceID == type(IPubkeyResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
