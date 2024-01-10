// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ConsumableAdapterV1.sol";
import "./IMetaverseAdditionFacet.sol";
import "./LibOwnership.sol";
import "./LibMetaverseConsumableAdapter.sol";
import "./LibMarketplace.sol";

contract MetaverseAdditionFacet is IMetaverseAdditionFacet {
    /// @notice Adds a Metaverse to LandWorks.
    /// @dev Deploys a consumable adapter for each metaverse registry.
    /// @param _metaverseId The id of the metaverse
    /// @param _name Name of the metaverse
    /// @param _metaverseRegistries A list of metaverse registries, that will be
    /// associated with the given metaverse id.
    /// @param _administrativeConsumers A list of administrative consumers, mapped
    /// 1:1 to its metaverse registry index. Used as a consumer when no active rents are
    /// active.
    function addMetaverseWithAdapters(
        uint256 _metaverseId,
        string calldata _name,
        address[] calldata _metaverseRegistries,
        address[] calldata _administrativeConsumers
    ) public {
        addMetaverse(
            _metaverseId,
            _name,
            _metaverseRegistries,
            _administrativeConsumers,
            true
        );
    }

    /// @notice Adds a Metaverse to LandWorks.
    /// @dev Sets the metaverse registries as consumable adapters.
    /// @param _metaverseId The id of the metaverse
    /// @param _name Name of the metaverse
    /// @param _metaverseRegistries A list of metaverse registries, that will be
    /// associated with the given metaverse id.
    /// @param _administrativeConsumers A list of administrative consumers, mapped
    /// 1:1 to its metaverse registry index. Used as a consumer when no active rents are
    /// active.
    function addMetaverseWithoutAdapters(
        uint256 _metaverseId,
        string calldata _name,
        address[] calldata _metaverseRegistries,
        address[] calldata _administrativeConsumers
    ) public {
        addMetaverse(
            _metaverseId,
            _name,
            _metaverseRegistries,
            _administrativeConsumers,
            false
        );
    }

    function addMetaverse(
        uint256 _metaverseId,
        string calldata _name,
        address[] calldata _metaverseRegistries,
        address[] calldata _administrativeConsumers,
        bool withAdapters
    ) internal {
        require(
            _metaverseRegistries.length == _administrativeConsumers.length,
            "invalid metaverse registries and operators length"
        );
        require(
            bytes(LibMarketplace.metaverseName(_metaverseId)).length == 0,
            "metaverse name already set"
        );
        require(
            LibMarketplace.totalRegistries(_metaverseId) == 0,
            "metaverse registries already exist"
        );
        LibOwnership.enforceIsContractOwner();

        LibMarketplace.setMetaverseName(_metaverseId, _name);
        emit SetMetaverseName(_metaverseId, _name);

        for (uint256 i = 0; i < _metaverseRegistries.length; i++) {
            address metaverseRegistry = _metaverseRegistries[i];
            address administrativeConsumer = _administrativeConsumers[i];

            require(
                metaverseRegistry != address(0),
                "_metaverseRegistry must not be 0x0"
            );
            LibMarketplace.setRegistry(_metaverseId, metaverseRegistry, true);
            emit SetRegistry(_metaverseId, metaverseRegistry, true);

            address adapter = metaverseRegistry;
            if (withAdapters) {
                adapter = address(
                    new ConsumableAdapterV1(address(this), metaverseRegistry)
                );
            }

            LibMetaverseConsumableAdapter
                .metaverseConsumableAdapterStorage()
                .consumableAdapters[metaverseRegistry] = adapter;
            emit ConsumableAdapterUpdated(metaverseRegistry, adapter);

            LibMetaverseConsumableAdapter
                .metaverseConsumableAdapterStorage()
                .administrativeConsumers[
                    metaverseRegistry
                ] = administrativeConsumer;

            emit AdministrativeConsumerUpdated(
                metaverseRegistry,
                administrativeConsumer
            );
        }
    }
}
