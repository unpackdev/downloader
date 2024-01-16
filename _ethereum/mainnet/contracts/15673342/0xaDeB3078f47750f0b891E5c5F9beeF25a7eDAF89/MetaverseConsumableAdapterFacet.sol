// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721Consumable.sol";
import "./IMetaverseConsumableAdapterFacet.sol";
import "./LibOwnership.sol";
import "./LibList.sol";
import "./LibMetaverseConsumableAdapter.sol";
import "./LibMarketplace.sol";
import "./LibRent.sol";

/// @notice A Metaverse related facet, that manages the logic
/// with metaverses having an external consumable adapter, used
/// to store consumers of LandWorks NFTs upon rentals.
contract MetaverseConsumableAdapterFacet is IMetaverseConsumableAdapterFacet {
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
    ) external returns (uint256) {
        uint256 assetId = LibList.list(
            _metaverseId,
            _metaverseRegistry,
            _metaverseAssetId,
            _minPeriod,
            _maxPeriod,
            _maxFutureTime,
            _paymentToken,
            _pricePerSecond,
            _referrer
        );

        updateAdapterAdministrativeOperator(
            assetId,
            _metaverseRegistry,
            _metaverseAssetId
        );

        return assetId;
    }

    /// @notice Sets the metaverse consumable adapter
    /// @param _metaverseRegistry The target metaverse registry (token address)
    /// @param _consumableAdapter The address of the consumable adapter
    function setConsumableAdapter(
        address _metaverseRegistry,
        address _consumableAdapter
    ) public {
        require(_metaverseRegistry != address(0), "_metaverse must not be 0x0");
        require(
            _consumableAdapter != address(0),
            "_consumableAdapter must not be 0x0"
        );
        LibOwnership.enforceIsContractOwner();

        LibMetaverseConsumableAdapter
            .metaverseConsumableAdapterStorage()
            .consumableAdapters[_metaverseRegistry] = _consumableAdapter;

        emit ConsumableAdapterUpdated(_metaverseRegistry, _consumableAdapter);
    }

    /// @notice Sets the metaverse administrative consumer, used
    /// as a consumer when LandWorks NFTs do not have an active rent.
    /// @param _metaverseRegistry The target metaverse registry (token address)
    /// @param _administrativeConsumer The target administrative consumer
    function setAdministrativeConsumerFor(
        address _metaverseRegistry,
        address _administrativeConsumer
    ) public {
        require(_metaverseRegistry != address(0), "_metaverse must not be 0x0");
        require(
            _administrativeConsumer != address(0),
            "_administrativeConsumer must not be 0x0"
        );
        LibOwnership.enforceIsContractOwner();

        LibMetaverseConsumableAdapter
            .metaverseConsumableAdapterStorage()
            .administrativeConsumers[
                _metaverseRegistry
            ] = _administrativeConsumer;

        emit AdministrativeConsumerUpdated(
            _metaverseRegistry,
            _administrativeConsumer
        );
    }

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
    ) public payable returns (uint256 rentId_, bool rentStartsNow_) {
        require(_consumer != address(0), "_consumer must not be 0x0");

        (rentId_, rentStartsNow_) = LibRent.rent(
            LibRent.RentParams({
                _assetId: _assetId,
                _period: _period,
                _maxRentStart: _maxRentStart,
                _paymentToken: _paymentToken,
                _amount: _amount,
                _referrer: _referrer
            })
        );

        LibMetaverseConsumableAdapter
            .metaverseConsumableAdapterStorage()
            .consumers[_assetId][rentId_] = _consumer;

        emit UpdateRentConsumer(_assetId, rentId_, _consumer);

        if (rentStartsNow_) {
            updateAdapterConsumer(_assetId, rentId_, _consumer);
        }
    }

    /// @notice Updates the consumer for the given rent of an asset
    /// @dev If the rent is active, it updates the metaverse consumable adapter consumer as well.
    /// @param _assetId The target asset
    /// @param _rentId The target rent for the asset
    /// @param _newConsumer The to-be-set new consumer
    function updateConsumer(
        uint256 _assetId,
        uint256 _rentId,
        address _newConsumer
    ) public {
        require(_newConsumer != address(0), "_newConsumer must not be 0x0");
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();
        require(LibERC721.exists(_assetId), "_assetId not found");

        require(
            msg.sender == ms.rents[_assetId][_rentId].renter,
            "caller is not renter"
        );
        LibMetaverseConsumableAdapter
            .metaverseConsumableAdapterStorage()
            .consumers[_assetId][_rentId] = _newConsumer;

        emit UpdateRentConsumer(_assetId, _rentId, _newConsumer);

        LibMarketplace.Rent memory rent = ms.rents[_assetId][_rentId];
        if (block.timestamp >= rent.start && block.timestamp < rent.end) {
            updateAdapterConsumer(_assetId, _rentId, _newConsumer);
        }
    }

    /// @notice Updates the consumer for the given asset in the metaverse consumable adapter with rent's provided consumer.
    /// When the rent becomes active (the current block.timestamp is between the rent's start and end),
    /// this function should be executed to set the provided rent consumer to the metaverse consumable adapter.
    /// @param _assetId The target asset which will map to its corresponding metaverse tokenId
    /// @param _rentId The target rent
    function updateAdapterState(uint256 _assetId, uint256 _rentId) public {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();
        require(LibERC721.exists(_assetId), "_assetId not found");
        LibMarketplace.Rent memory rent = ms.rents[_assetId][_rentId];

        require(
            block.timestamp >= rent.start,
            "block timestamp less than rent start"
        );
        require(
            block.timestamp < rent.end,
            "block timestamp more than or equal to rent end"
        );
        address consumer = LibMetaverseConsumableAdapter
            .metaverseConsumableAdapterStorage()
            .consumers[_assetId][_rentId];

        updateAdapterConsumer(_assetId, _rentId, consumer);
    }

    /// @notice Updates the asset's metaverse tokenId with the administrative consumer in the metaverse consumable adapter
    /// @dev This can be done only when the asset has no active rents.
    /// @param _assetId The target asset which will map to its corresponding metaverse tokenId
    function updateAdapterAdministrativeState(uint256 _assetId) public {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();
        require(LibERC721.exists(_assetId), "_assetId not found");
        LibMarketplace.Asset memory asset = ms.assets[_assetId];

        require(
            block.timestamp > ms.rents[_assetId][asset.totalRents].end,
            "_assetId has an active rent"
        );

        updateAdapterAdministrativeOperator(
            _assetId,
            asset.metaverseRegistry,
            asset.metaverseAssetId
        );
    }

    function updateAdapterAdministrativeOperator(
        uint256 _assetId,
        address _metaverseRegistry,
        uint256 _metaverseAssetId
    ) internal {
        LibMetaverseConsumableAdapter.MetaverseConsumableAdapterStorage
            storage mcas = LibMetaverseConsumableAdapter
                .metaverseConsumableAdapterStorage();

        address consumer = mcas.administrativeConsumers[_metaverseRegistry];
        address adapter = mcas.consumableAdapters[_metaverseRegistry];
        IERC721Consumable(adapter).changeConsumer(consumer, _metaverseAssetId);

        emit UpdateAdapterAdministrativeConsumer(_assetId, adapter, consumer);
    }

    /// @dev Updates the metaverse consumable adapter for the asset's metaverse tokenId
    /// with the provided consumer
    /// @param _assetId The target asset
    /// @param _rentId The target rent. Used only for event emission.
    /// @param _consumer The rent's consumer
    function updateAdapterConsumer(
        uint256 _assetId,
        uint256 _rentId,
        address _consumer
    ) internal {
        LibMarketplace.Asset memory asset = LibMarketplace
            .marketplaceStorage()
            .assets[_assetId];
        address adapter = LibMetaverseConsumableAdapter
            .metaverseConsumableAdapterStorage()
            .consumableAdapters[asset.metaverseRegistry];

        IERC721Consumable(adapter).changeConsumer(
            _consumer,
            asset.metaverseAssetId
        );

        emit UpdateAdapterConsumer(_assetId, _rentId, adapter, _consumer);
    }

    /// @notice Gets the consumer of the rent for the asset
    /// @param _assetId The target asset
    /// @param _rentId The target rent
    function rentConsumer(uint256 _assetId, uint256 _rentId)
        public
        view
        returns (address)
    {
        return
            LibMetaverseConsumableAdapter
                .metaverseConsumableAdapterStorage()
                .consumers[_assetId][_rentId];
    }

    /// @notice Gets the administrative consumer of a metaverseRegistry
    /// @param _metaverseRegistry The target metaverse registry (token address)
    function administrativeConsumer(address _metaverseRegistry)
        public
        view
        returns (address)
    {
        return
            LibMetaverseConsumableAdapter
                .metaverseConsumableAdapterStorage()
                .administrativeConsumers[_metaverseRegistry];
    }

    /// @notice Gets the consumable adapter of a metaverse
    /// @param _metaverseRegistry The target metaverse registry (token address)
    function consumableAdapter(address _metaverseRegistry)
        public
        view
        returns (address)
    {
        return
            LibMetaverseConsumableAdapter
                .metaverseConsumableAdapterStorage()
                .consumableAdapters[_metaverseRegistry];
    }
}
