//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IENSReverseRegistrar {
    function node(address addr) external pure returns (bytes32);
}

interface IENSRegistryWithFallback {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSReverseResolver {
    function name(bytes32 node) external view returns (string memory);
}

contract ENSHelpers is Ownable {
    IENSReverseRegistrar public reverseRegistrar;
    IENSRegistryWithFallback public registryWithFallback;

    constructor(address _reverseRegistrar, address _registryWithFallbackAddress) {
        reverseRegistrar = IENSReverseRegistrar(_reverseRegistrar);
        registryWithFallback = IENSRegistryWithFallback(_registryWithFallbackAddress);
    }

    function updateENSAddress(address _reverseRegistrar, address _registryWithFallbackAddress) external onlyOwner {
        reverseRegistrar = IENSReverseRegistrar(_reverseRegistrar);
        registryWithFallback = IENSRegistryWithFallback(_registryWithFallbackAddress);
    }

    function getEnsDomain(address _address) external view returns (string memory) {
        bytes32 node = reverseRegistrar.node(_address);
        address resolver = registryWithFallback.resolver(node);

        if (resolver != address(0)) {
            IENSReverseResolver reverseResolver = IENSReverseResolver(resolver);
            return reverseResolver.name(node);
        }

        return "";
    }
}
