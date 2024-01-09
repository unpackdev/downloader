// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external  returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external  view returns (address);
    function resolver(bytes32 node) external  view returns (address);
    function ttl(bytes32 node) external  view returns (uint64);
    function recordExists(bytes32 node) external  view returns (bool);
    function isApprovedForAll(address owner, address operator) external  view returns (bool);
}

abstract contract EnsOwnable {

    address private _ensRegistry = address(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    bool requireENS = true;

    function node(address addr) pure internal returns (bytes32 ret) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
    }

    function contractDeployed(address addr) internal view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }

    function hasENS(address addr) internal view returns(bool) {
      if (!contractDeployed(_ensRegistry)) {
        return true; //local chain, bypass
      }
      bytes32 namehash = node(addr);
      return IENS(_ensRegistry).owner(namehash) != address(0);
    }

    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    modifier onlyEnsOwner() {
      if (requireENS) {
            require(hasENS(msg.sender), "only for ENS owner");
      }
      _;
    }

}


