// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibMetaverseConsumableAdapter {
    bytes32 constant METAVERSE_CONSUMABLE_ADAPTER_POSITION =
        keccak256("com.enterdao.landworks.metaverse.consumable.adapter");

    struct MetaverseConsumableAdapterStorage {
        // Stores the adapters for each metaverse
        mapping(address => address) consumableAdapters;
        // Stores the administrative consumers for each metaverse
        mapping(address => address) administrativeConsumers;
        // Stores the consumers for each asset's rentals
        mapping(uint256 => mapping(uint256 => address)) consumers;
    }

    function metaverseConsumableAdapterStorage()
        internal
        pure
        returns (MetaverseConsumableAdapterStorage storage mcas)
    {
        bytes32 position = METAVERSE_CONSUMABLE_ADAPTER_POSITION;

        assembly {
            mcas.slot := position
        }
    }
}
