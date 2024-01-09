// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDecentralandRegistry {
    /// @notice Set Estate/LAND updateOperator
    /// @param _assetId - Estate/LAND id
    /// @param _operator - the to-be-set as operator
    function setUpdateOperator(uint256 _assetId, address _operator) external;
}
