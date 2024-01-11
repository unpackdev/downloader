// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC1967UUPSUpgradeable.sol";

interface Resolver {
  function addr(bytes32 node) external view returns (address);
}

interface ENS {
  function resolver(bytes32 node) external view returns (Resolver);
}

contract ERC1967UUPSENSUpgradeable is ERC1967UUPSUpgradeable {
  ENS internal constant _ENS = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
  bytes32 internal immutable _OWNER_NAMEHASH;

  constructor (string[] memory ensName) {
    bytes32 namehash;
    for (uint256 i; i < ensName.length; i++) {
      namehash = keccak256(bytes.concat(namehash, keccak256(bytes(ensName[i]))));
    }
    _OWNER_NAMEHASH = namehash;
  }

  function _owner() internal view returns (address) {
    return _ENS.resolver(_OWNER_NAMEHASH).addr(_OWNER_NAMEHASH);
  }

  function owner() public view onlyProxy returns (address) {
    return _owner();
  }

  function _requireOwner() internal view {
    require(_msgSender() == _owner(), "ERC1967UUPSENSUpgradeable: only owner");
  }

  modifier onlyOwner() {
    _requireProxy();
    _requireOwner();
    _;
  }

  function initialize() public virtual override {
    _requireOwner();
    super.initialize();
  }

  function upgrade(address newImplementation) public payable virtual override {
    _requireOwner();
    super.upgrade(newImplementation);
  }

  function upgradeAndCall(address newImplementation, bytes calldata data) public payable virtual override {
    _requireOwner();
    super.upgradeAndCall(newImplementation, data);
  }
}
