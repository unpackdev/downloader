// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDecentralandRegistry {
    /// @notice Set Estate/LAND updateOperator
    /// @param _assetId - Estate/LAND id
    /// @param _operator - the to-be-set as operator
    function setUpdateOperator(uint256 _assetId, address _operator) external;

    /// @notice Sets LANDs operator inside of an Estate.
    /// @dev LANDs' operators, which are part of an Estate, are not cleared upon estate transfer.
    /// @param _estateId - The target Estate id.
    /// @param _landIds - An array of LANDs, which are part of the estate.
    /// @param _operator - The operator to-be-set to the lands.
    function setManyLandUpdateOperator(
        uint256 _estateId,
        uint256[] memory _landIds,
        address _operator
    ) external;
}
