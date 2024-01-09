// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IDecentralandFacet.sol";
import "./IDecentralandRegistry.sol";
import "./LibOwnership.sol";
import "./LibRent.sol";
import "./LibDecentraland.sol";

contract DecentralandFacet is IDecentralandFacet {
    /// @notice Rents Decentraland Estate/LAND.
    /// @param _assetId The target asset
    /// @param _period The target period of the rental
    /// @param _operator The target operator, which will be set as operator once the rent is active
    function rentDecentraland(
        uint256 _assetId,
        uint256 _period,
        address _operator
    ) external payable {
        require(_operator != address(0), "_operator must not be 0x0");

        (uint256 rentId, bool rentStartsNow) = LibRent.rent(_assetId, _period);
        LibDecentraland.setOperator(_assetId, rentId, _operator);
        emit UpdateOperator(_assetId, rentId, _operator);

        if (rentStartsNow) {
            updateState(_assetId, rentId);
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

        LibMarketplace.Asset memory asset = ms.assets[_assetId];
        address operator = LibDecentraland.decentralandStorage().operators[
            _assetId
        ][_rentId];

        IDecentralandRegistry(asset.metaverseRegistry).setUpdateOperator(
            asset.metaverseAssetId,
            operator
        );

        emit UpdateState(_assetId, _rentId, operator);
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

        address operator = LibDecentraland
            .decentralandStorage()
            .administrativeOperator;
        IDecentralandRegistry(asset.metaverseRegistry).setUpdateOperator(
            asset.metaverseAssetId,
            operator
        );
        emit UpdateAdministrativeState(_assetId, operator);
    }

    /// @notice Updates the operator for the given rent of an asset
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
