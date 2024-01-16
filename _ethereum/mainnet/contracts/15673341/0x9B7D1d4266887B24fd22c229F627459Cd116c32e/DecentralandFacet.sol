// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IDecentralandFacet.sol";
import "./IDecentralandRegistry.sol";
import "./LibOwnership.sol";
import "./LibDecentraland.sol";
import "./LibList.sol";
import "./LibRent.sol";

contract DecentralandFacet is IDecentralandFacet {
    /// @notice Provides asset of the given metaverse registry for rental.
    /// Transfers and locks the provided metaverse asset to the contract.
    /// and mints an asset, representing the locked asset.
    /// Listing with a referrer might lead to additional rewards upon rents.
    /// Additional reward may vary depending on the referrer's requested portion for listers.
    /// If the referrer is blacklisted after the listing,
    /// listers will not receive additional rewards.
    /// See {IReferralFacet-setMetaverseRegistryReferrers}, {IReferralFacet-setReferrers}.
    /// Updates the corresponding Estate/LAND operator with the administrative operator.
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
    function listDecentraland(
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

        updateAdministrativeOperator(
            assetId,
            _metaverseRegistry,
            _metaverseAssetId
        );

        return assetId;
    }

    /// @notice Rents Decentraland Estate/LAND.
    /// @param _assetId The target asset
    /// @param _period The target period of the rental
    /// @param _maxRentStart The maximum rent start allowed for the given rent
    /// @param _operator The target operator, which will be set as operator once the rent is active
    /// @param _paymentToken The current payment token for the asset
    /// @param _amount The target amount to be paid for the rent
    /// @param _referrer The target referrer
    /// @return rentId_ The id of the rent for the target asset
    /// @return rentStartsNow_ Whether the rents begins in the current block
    function rentDecentraland(
        uint256 _assetId,
        uint256 _period,
        uint256 _maxRentStart,
        address _operator,
        address _paymentToken,
        uint256 _amount,
        address _referrer
    ) external payable returns (uint256 rentId_, bool rentStartsNow_) {
        require(_operator != address(0), "_operator must not be 0x0");

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
        LibDecentraland.setOperator(_assetId, rentId_, _operator);
        emit UpdateOperator(_assetId, rentId_, _operator);

        if (rentStartsNow_) {
            updateState(_assetId, rentId_);
        }
    }

    /// @notice Updates the corresponding Estate/LAND operator from the given rent.
    /// When the rent becomes active (the current block.timestamp is between the rent's start and end),
    /// this function should be executed to set the provided rent operator to the Estate/LAND scene operator.
    /// @param _assetId The target asset which will map to its corresponding Estate/LAND
    /// @param _rentId The target rent
    function updateState(uint256 _assetId, uint256 _rentId) public {
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
        address operator = LibDecentraland.decentralandStorage().operators[
            _assetId
        ][_rentId];

        updateState(_assetId, _rentId, operator);
    }

    /// @notice Updates the corresponding Estate/LAND operator with the administrative operator
    /// @param _assetId The target asset which will map to its corresponding Estate/LAND
    function updateAdministrativeState(uint256 _assetId) external {
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();
        require(LibERC721.exists(_assetId), "_assetId not found");
        LibMarketplace.Asset memory asset = ms.assets[_assetId];

        require(
            block.timestamp > ms.rents[_assetId][asset.totalRents].end,
            "_assetId has an active rent"
        );

        updateAdministrativeOperator(
            _assetId,
            asset.metaverseRegistry,
            asset.metaverseAssetId
        );
    }

    /// @notice Updates the operator for the given rent of an asset
    /// @dev If the rent is active, it updates the corresponding Estate/LAND scene registry operator as well.
    /// @param _assetId The target asset
    /// @param _rentId The target rent for the asset
    /// @param _newOperator The to-be-set new operator
    function updateOperator(
        uint256 _assetId,
        uint256 _rentId,
        address _newOperator
    ) external {
        require(_newOperator != address(0), "_newOperator must not be 0x0");
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();
        require(LibERC721.exists(_assetId), "_assetId not found");

        require(
            msg.sender == ms.rents[_assetId][_rentId].renter,
            "caller is not renter"
        );
        LibDecentraland.setOperator(_assetId, _rentId, _newOperator);
        emit UpdateOperator(_assetId, _rentId, _newOperator);

        LibMarketplace.Rent memory rent = ms.rents[_assetId][_rentId];
        if (block.timestamp >= rent.start && block.timestamp < rent.end) {
            updateState(_assetId, _rentId, _newOperator);
        }
    }

    function updateState(
        uint256 _assetId,
        uint256 _rentId,
        address _operator
    ) internal {
        LibMarketplace.Asset memory asset = LibMarketplace
            .marketplaceStorage()
            .assets[_assetId];
        IDecentralandRegistry(asset.metaverseRegistry).setUpdateOperator(
            asset.metaverseAssetId,
            _operator
        );

        emit UpdateState(_assetId, _rentId, _operator);
    }

    /// @notice Updates the administrative operator
    /// @param _administrativeOperator The to-be-set administrative operator
    function updateAdministrativeOperator(address _administrativeOperator)
        external
    {
        require(
            _administrativeOperator != address(0),
            "_administrativeOperator must not be 0x0"
        );
        LibOwnership.enforceIsContractOwner();

        LibDecentraland.setAdministrativeOperator(_administrativeOperator);

        emit UpdateAdministrativeOperator(_administrativeOperator);
    }

    function updateAdministrativeOperator(
        uint256 _assetId,
        address _metaverseRegistry,
        uint256 _metaverseAssetId
    ) internal {
        address operator = LibDecentraland
            .decentralandStorage()
            .administrativeOperator;
        IDecentralandRegistry(_metaverseRegistry).setUpdateOperator(
            _metaverseAssetId,
            operator
        );
        emit UpdateAdministrativeState(_assetId, operator);
    }

    /// @notice Clears the operators of Decentraland LANDs, which are part of a Decentraland Estate.
    /// @dev LANDs' operators, which are part of an Estate, are not cleared upon Estate transfer.
    /// The function's goal is to have the possibility to clear the operators of LANDs, which have been set
    /// before the estate has been listed in LandWorks, otherwise whenever someone rents the estate, there might
    /// be other operators, who can override the renter's scene.
    /// @param _assetIds - The list of LandWorks asset ids.
    /// @param _landIds - The list of landIds for each asset.
    function clearEstateLANDOperators(
        uint256[] memory _assetIds,
        uint256[][] memory _landIds
    ) external {
        require(
            _assetIds.length == _landIds.length,
            "_assetIds and _landIds length must match"
        );
        LibMarketplace.MarketplaceStorage storage ms = LibMarketplace
            .marketplaceStorage();

        for (uint256 i = 0; i < _landIds.length; i++) {
            LibMarketplace.Asset memory asset = ms.assets[_assetIds[i]];

            IDecentralandRegistry(asset.metaverseRegistry)
                .setManyLandUpdateOperator(
                    asset.metaverseAssetId,
                    _landIds[i],
                    address(0)
                );
        }
    }

    /// @notice Gets the administrative operator
    function administrativeOperator() external view returns (address) {
        return LibDecentraland.administrativeOperator();
    }

    /// @notice Gets the operator of the rent for the an asset
    /// @param _assetId The target asset
    /// @param _rentId The target rentId
    function operatorFor(uint256 _assetId, uint256 _rentId)
        external
        view
        returns (address)
    {
        return LibDecentraland.operatorFor(_assetId, _rentId);
    }
}
