//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface EnsRegistry {
    function resolver(bytes32 node) external view returns (address);
}

interface EnsResolver {
    function addr(bytes32 node) external view returns (address);
}

library EnsLibrary {
    function ensNodeToAddressFromEnsRegistry(
        address ensRegistry,
        bytes32 ensNode
    ) internal view returns (address) {
        address resolver = EnsRegistry(ensRegistry).resolver(ensNode);
        require(resolver != address(0), "The resolver for ensNode DNE");
        address addr = EnsResolver(resolver).addr(ensNode);
        require(addr != address(0), "The address for resolver DNE");
        return addr;
    }
}
