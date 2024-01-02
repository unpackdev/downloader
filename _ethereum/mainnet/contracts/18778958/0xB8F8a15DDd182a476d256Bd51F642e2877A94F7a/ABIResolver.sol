// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "./ResolverBase.sol";

abstract contract ABIResolver is IABIResolver, ResolverBase {
  mapping(uint64 => mapping(bytes32 => mapping(uint256 => bytes))) versionable_abis;

  function setABI(
    bytes32 node,
    uint256 contentType,
    bytes calldata data
  ) external virtual authorised(node) {
    // Content types must be powers of 2
    require(((contentType - 1) & contentType) == 0);

    versionable_abis[recordVersions[node]][node][contentType] = data;
    emit ABIChanged(node, contentType);
  }

  function ABI(
    bytes32 node,
    uint256 contentTypes
  ) external view virtual override returns (uint256, bytes memory) {
    mapping(uint256 => bytes) storage abiset = versionable_abis[
      recordVersions[node]
    ][node];

    for (
      uint256 contentType = 1;
      contentType <= contentTypes;
      contentType <<= 1
    ) {
      if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
        return (contentType, abiset[contentType]);
      }
    }

    return (0, bytes(""));
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view virtual override returns (bool) {
    return
      interfaceID == type(IABIResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
