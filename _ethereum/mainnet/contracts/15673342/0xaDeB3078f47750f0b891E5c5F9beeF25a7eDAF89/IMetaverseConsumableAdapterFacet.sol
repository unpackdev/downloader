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

    /// @notice Provides asset of the given metaverse registry for rental.
    /// Transfers and locks the provided metaverse asset to the contract.
    /// and mints an asset, representing the locked asset.
    /// Listing with a referrer might lead to additional rewards upon rents.
    /// Additional reward may vary depending on the referrer's requested portion for listers.
    /// If the referrer is blacklisted after the listing,
    /// listers will not receive additional rewards.
    /// See {IReferralFacet-setMetaverseRegistryReferrers}, {IReferralFacet-setReferrers}.
    /// Updates the corresponding Metaverse Consumer Adapter with the administrative operator.
    /// @param _metaverseId The id of the metaverse
    /// @param _metaverseRegistry The registry of the metaverse
    /// @param _metaverseAssetId The id from the metaverse registry
    /// @param _minPeriod The minimum number of time (in seconds) the asset can be rented
    /// @param _maxPeriod The maximum number of time (in seconds) the asset can be rented
    /// @param _maxFutureTime The timestamp delta after which the protocol will not allow
    /// the asset to be rented at an any given moment.
    /// @param _paymentToken The token which will be accepted as a form of payment.
    /// Provide 0x0000000000000000000000000000000000000001 for ETH.
    /// @param _pricePerSecond The price for rental per second
    /// @param _referrer The target referrer
    /// @return The newly created asset id.
    function listWithConsumableAdapter(
        uint256 _metaverseId,
        address _metaverseRegistry,
        uint256 _metaverseAssetId,
        uint256 _minPeriod,
        uint256 _maxPeriod,
        uint256 _maxFutureTime,
        address _paymentToken,
        uint256 _pricePerSecond,
        address _referrer
    ) external returns (uint256);

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
    /// @param _referrer The target referrer
    /// @return rentId_ The id of the rent for the target asset
    /// @return rentStartsNow_ Whether the rents begins in the current block
    function rentWithConsumer(
        uint256 _assetId,
        uint256 _period,
        uint256 _maxRentStart,
        address _consumer,
        address _paymentToken,
        uint256 _amount,
        address _referrer
    ) external payable returns (uint256 rentId_, bool rentStartsNow_);

    /// @notice Updates the consumer for the given rent of an asset
    /// @dev If the rent is active, it updates the metaverse consumable adapter consumer as well.
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
