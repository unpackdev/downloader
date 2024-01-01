// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

address constant ENS_LOOKUP = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
address constant ENS_REVERSE_LOOKUP = 0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C;

interface IResolver {
    function addr(bytes32 node) external view returns (address);
    function setAddr(bytes32 node, address addr) external;
    function setName(bytes32 node, string calldata _name) external;
}

interface IEns {
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

    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IReverseEns {
    function getNames(address[] calldata addresses) external view returns (string[] memory r);
}

interface IEnsReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(address addr, address owner, address resolver) external returns (bytes32);

    function claimWithResolver(address owner, address resolver) external returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(address addr, address owner, address resolver, string memory name)
        external
        returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}
