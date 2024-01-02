// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ResolverBase.sol";
import "./IContentHashResolver.sol";

abstract contract ContentHashResolver is IContentHashResolver, ResolverBase {
  mapping(uint64 => mapping(bytes32 => bytes)) versionable_hashes;

  function setContenthash(
    bytes32 node,
    bytes calldata hash
  ) external virtual authorised(node) {
    versionable_hashes[recordVersions[node]][node] = hash;
    emit ContenthashChanged(node, hash);
  }

  function contenthash(
    bytes32 node
  ) external view virtual override returns (bytes memory) {
    return versionable_hashes[recordVersions[node]][node];
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view virtual override returns (bool) {
    return
      interfaceID == type(IContentHashResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
