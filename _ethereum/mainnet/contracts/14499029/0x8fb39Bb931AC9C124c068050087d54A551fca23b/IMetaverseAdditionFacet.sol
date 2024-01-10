// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMetaverseAdditionFacet {
    event SetMetaverseName(uint256 indexed _metaverseId, string _name);

    event SetRegistry(
        uint256 indexed _metaverseId,
        address _registry,
        bool _status
    );

    event ConsumableAdapterUpdated(
        address indexed _metaverseRegistry,
        address indexed _adapter
    );

    event AdministrativeConsumerUpdated(
        address indexed _metaverseRegistry,
        address indexed _administrativeConsumer
    );

    function addMetaverseWithAdapters(
        uint256 _metaverseId,
        string calldata _name,
        address[] calldata _metaverseRegistries,
        address[] calldata _administrativeConsumers
    ) external;

    function addMetaverseWithoutAdapters(
        uint256 _metaverseId,
        string calldata _name,
        address[] calldata _metaverseRegistries,
        address[] calldata _administrativeConsumers
    ) external;
}
