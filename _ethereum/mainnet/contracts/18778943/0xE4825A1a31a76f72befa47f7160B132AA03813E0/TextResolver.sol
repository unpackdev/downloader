// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ResolverBase.sol";
import "./ITextResolver.sol";

abstract contract TextResolver is ITextResolver, ResolverBase {
  mapping(uint64 => mapping(bytes32 => mapping(string => string))) versionable_texts;

  function setText(
    bytes32 node,
    string calldata key,
    string calldata value
  ) external virtual authorised(node) {
    versionable_texts[recordVersions[node]][node][key] = value;
    emit TextChanged(node, key, key, value);
  }

  function text(
    bytes32 node,
    string calldata key
  ) external view virtual override returns (string memory) {
    return versionable_texts[recordVersions[node]][node][key];
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view virtual override returns (bool) {
    return
      interfaceID == type(ITextResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
