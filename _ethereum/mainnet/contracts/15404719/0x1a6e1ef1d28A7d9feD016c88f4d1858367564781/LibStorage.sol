// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("xyz.swidge.storage.diamond");
    bytes32 constant PROVIDERS_STORAGE_POSITION = keccak256("xyz.swidge.storage.app");

    struct DiamondStorage {
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;
        address contractOwner;
        address relayerAddress;
    }

    struct ProviderStorage {
        mapping(uint8 => Provider) bridgeProviders;
        mapping(uint8 => Provider) swapProviders;
        uint16 totalBridges;
        uint16 totalSwappers;
    }

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct Provider {
        uint8 code;
        bool enabled;
        address implementation;
        address handler;
    }

    function diamond() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function providers() internal pure returns (ProviderStorage storage ps) {
        bytes32 position = PROVIDERS_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamond().contractOwner, "Must be contract owner");
    }

    function enforceIsRelayer() internal view {
        require(msg.sender == diamond().relayerAddress, "Must be relayer");
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}