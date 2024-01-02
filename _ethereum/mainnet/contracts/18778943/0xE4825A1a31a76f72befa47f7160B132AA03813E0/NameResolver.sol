// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ResolverBase.sol";
import "./INameResolver.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
  mapping(uint64 => mapping(bytes32 => string)) versionable_names;

  function setName(
    bytes32 node,
    string calldata newName
  ) external virtual authorised(node) {
    versionable_names[recordVersions[node]][node] = newName;
    emit NameChanged(node, newName);
  }

  function name(
    bytes32 node
  ) external view virtual override returns (string memory) {
    return versionable_names[recordVersions[node]][node];
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view virtual override returns (bool) {
    return
      interfaceID == type(INameResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
