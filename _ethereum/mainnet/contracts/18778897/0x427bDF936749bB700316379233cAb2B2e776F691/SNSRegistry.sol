// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SNS.sol";

contract SNSRegistry is SNS {
  struct Record {
    address owner;
    address resolver;
    uint64 ttl;
  }

  mapping(bytes32 => Record) records;
  mapping(address => mapping(address => bool)) operators;

  modifier authorised(bytes32 node) {
    address owner = records[node].owner;
    require(owner == msg.sender || operators[owner][msg.sender]);
    _;
  }

  constructor() {
    records[0x0].owner = msg.sender;
  }

  function setRecord(
    bytes32 node,
    address owner,
    address resolver,
    uint64 ttl
  ) external virtual override {
    setOwner(node, owner);
    _setResolverAndTTL(node, resolver, ttl);
  }

  function setSubnodeRecord(
    bytes32 node,
    bytes32 label,
    address owner,
    address resolver,
    uint64 ttl
  ) external virtual override {
    bytes32 subnode = setSubnodeOwner(node, label, owner);
    _setResolverAndTTL(subnode, resolver, ttl);
  }

  function setOwner(
    bytes32 node,
    address owner
  ) public virtual override authorised(node) {
    _setOwner(node, owner);
    emit Transfer(node, owner);
  }

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) public virtual override authorised(node) returns (bytes32) {
    bytes32 subnode = keccak256(abi.encodePacked(node, label));
    _setOwner(subnode, owner);
    emit NewOwner(node, label, owner);
    return subnode;
  }

  function setResolver(
    bytes32 node,
    address resolver
  ) public virtual override authorised(node) {
    emit NewResolver(node, resolver);
    records[node].resolver = resolver;
  }

  function setTTL(
    bytes32 node,
    uint64 ttl
  ) public virtual override authorised(node) {
    emit NewTTL(node, ttl);
    records[node].ttl = ttl;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) external virtual override {
    operators[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function owner(bytes32 node) public view virtual override returns (address) {
    address addr = records[node].owner;
    if (addr == address(this)) {
      return address(0x0);
    }

    return addr;
  }

  function resolver(
    bytes32 node
  ) public view virtual override returns (address) {
    return records[node].resolver;
  }

  function ttl(bytes32 node) public view virtual override returns (uint64) {
    return records[node].ttl;
  }

  function recordExists(
    bytes32 node
  ) public view virtual override returns (bool) {
    return records[node].owner != address(0x0);
  }

  function isApprovedForAll(
    address owner,
    address operator
  ) external view virtual override returns (bool) {
    return operators[owner][operator];
  }

  function _setOwner(bytes32 node, address owner) internal virtual {
    records[node].owner = owner;
  }

  function _setResolverAndTTL(
    bytes32 node,
    address resolver,
    uint64 ttl
  ) internal {
    if (resolver != records[node].resolver) {
      records[node].resolver = resolver;
      emit NewResolver(node, resolver);
    }

    if (ttl != records[node].ttl) {
      records[node].ttl = ttl;
      emit NewTTL(node, ttl);
    }
  }
}
