// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMetaverseConsumableAdapterFacet {
    event ConsumableAdapterUpdated(
        address indexed _metaverseRegistry,
        address indexed _adapter
    );

    event AdministrativeConsumerUpdated(
        address indexed _metaverseRegistry,
        address indexed _administrativeConsumer
    );

    event UpdateRentConsumer(
        uint256 indexed _assetId,
        uint256 _rentId,
        address indexed _consumer
    );

    event UpdateAdapterConsumer(
        uint256 indexed _assetId,
        uint256 _rentId,
        address indexed _adapter,
        address indexed _consumer
    );

    event UpdateAdapterAdministrativeConsumer(
        uint256 indexed _assetId,
        address indexed _adapter,
        address indexed _consumer
    );

    /// @notice Sets the metaverse consumable adapter
    /// @param _metaverseRegistry The target metaverse registry (token address)
    /// @param _consumableAdapter The address of the consumable adapter
    function setConsumableAdapter(
        address _metaverseRegistry,
        address _consumableAdapter
    ) external;

    /// @notice Sets the metaverse administrative consumer, used
    /// as a consumer when LandWorks NFTs do not have an active rent.
    /// @param _metaverseRegistry The target metaverse registry (token address)
    /// @param _administrativeConsumer The target administrative consumer
    function setAdministrativeConsumerFor(
        address _metaverseRegistry,
        address _administrativeConsumer
    ) external;

    /// @notice Rents an asset, providing a consumer that will consume the asset
    /// during its rental period.
    /// @dev The asset's metaverse must have previously set a metaverse consumable adapter.
    /// @dev If there are no active rents, this rent will begin, which will set
    /// the consumer directly in the metaverse consumable adapter.
    /// If there are any active or upcoming rents, when this rent's time comes,
    /// {IMetaverseConsumableAdapterFacet-updateAdapterState} must be called
    /// in order to set the consumer in the metaverse consumable adapter.
    /// @param _assetId The target asset
    /// @param _period The target period of the rental
    /// @param _maxRentStart The maximum rent start allowed for the given rent
    /// @param _consumer The target consumer, which will be set as consumer in the
    /// consumable adapter once the rent is active
    /// @param _paymentToken The current payment token for the asset
    /// @param _amount The target amount to be paid for the rent
    function rentWithConsumer(
        uint256 _assetId,
        uint256 _period,
        uint256 _maxRentStart,
        address _consumer,
        address _paymentToken,
        uint256 _amount
    ) external payable;

    /// @notice Updates the consumer for the given rent of an asset
    /// @dev If the current rent is active, after you update the consumer,
    /// you will need to update the consumer in the metaverse consumable adapter as well.
    /// @param _assetId The target asset
    /// @param _rentId The target rent for the asset
    /// @param _newConsumer The to-be-set new consumer
    function updateConsumer(
        uint256 _assetId,
        uint256 _rentId,
        address _newConsumer
    ) external;

    /// @notice Updates the consumer for the given asset in the metaverse consumable adapter with rent's provided consumer.
    /// When the rent becomes active (the current block.timestamp is between the rent's start and end),
    /// this function should be executed to set the provided rent consumer to the metaverse consumable adapter.
    /// @param _assetId The target asset which will map to its corresponding metaverse tokenId
    /// @param _rentId The target rent
    function updateAdapterState(uint256 _assetId, uint256 _rentId) external;

    /// @notice Updates the asset's metaverse tokenId with the administrative consumer in the metaverse consumable adapter
    /// @dev This can be done only when the asset has no active rents.
    /// @param _assetId The target asset which will map to its corresponding metaverse tokenId
    function updateAdapterAdministrativeState(uint256 _assetId) external;

    /// @notice Gets the consumer of the rent for the asset
    /// @param _assetId The target asset
    /// @param _rentId The target rent
    function rentConsumer(uint256 _assetId, uint256 _rentId)
        external
        view
        returns (address);

    /// @notice Gets the administrative consumer of a metaverseRegistry
    /// @param _metaverseRegistry The target metaverse registry (token address)
    function administrativeConsumer(address _metaverseRegistry)
        external
        view
        returns (address);

    /// @notice Gets the consumable adapter of a metaverse
    /// @param _metaverseRegistry The target metaverse registry (token address)
    function consumableAdapter(address _metaverseRegistry)
        external
        view
        returns (address);
}
