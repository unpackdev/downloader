// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC165.sol";
import "./ResolverBase.sol";
import "./AddrResolver.sol";
import "./IInterfaceResolver.sol";

abstract contract InterfaceResolver is IInterfaceResolver, AddrResolver {
  mapping(uint64 => mapping(bytes32 => mapping(bytes4 => address))) versionable_interfaces;

  function setInterface(
    bytes32 node,
    bytes4 interfaceID,
    address implementer
  ) external virtual authorised(node) {
    versionable_interfaces[recordVersions[node]][node][
      interfaceID
    ] = implementer;
    emit InterfaceChanged(node, interfaceID, implementer);
  }

  function interfaceImplementer(
    bytes32 node,
    bytes4 interfaceID
  ) external view virtual override returns (address) {
    address implementer = versionable_interfaces[recordVersions[node]][node][
      interfaceID
    ];
    if (implementer != address(0)) {
      return implementer;
    }

    address a = addr(node);
    if (a == address(0)) {
      return address(0);
    }

    (bool success, bytes memory returnData) = a.staticcall(
      abi.encodeWithSignature(
        "supportsInterface(bytes4)",
        type(IERC165).interfaceId
      )
    );
    if (!success || returnData.length < 32 || returnData[31] == 0) {
      // EIP 165 not supported by target
      return address(0);
    }

    (success, returnData) = a.staticcall(
      abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID)
    );
    if (!success || returnData.length < 32 || returnData[31] == 0) {
      // Specified interface not supported by target
      return address(0);
    }

    return a;
  }

  function supportsInterface(
    bytes4 interfaceID
  ) public view virtual override returns (bool) {
    return
      interfaceID == type(IInterfaceResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }
}
