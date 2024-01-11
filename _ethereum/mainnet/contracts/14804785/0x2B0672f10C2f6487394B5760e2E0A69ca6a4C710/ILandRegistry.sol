// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

/// @title Decentraland LAND interface
/// @author Rentable Team <hello@rentable.world>
interface ILandRegistry {
    /* ========== VIEWS ========== */

    /// @notice Show current land operator, who can update content
    /// @param assetId land identifier
    function updateOperator(uint256 assetId)
        external
        view
        returns (address operator);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Update current land operator, who can update content
    /// @param assetId land identifier
    /// @param operator operator address
    function setUpdateOperator(uint256 assetId, address operator) external;
}
