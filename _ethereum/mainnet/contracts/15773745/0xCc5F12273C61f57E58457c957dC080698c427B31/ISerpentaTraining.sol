// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAccessControlEnumerableUpgradeable.sol";

interface ISerpentaTraining is IAccessControlEnumerableUpgradeable {
    /* ------------------------------------------------------------------------------------------ */
    /*                                           ERRORS                                           */
    /* ------------------------------------------------------------------------------------------ */

    /// @dev Thrown when providing no token IDs.
    error InvalidTokens();

    /// @dev Thrown when trying to disableTraining when having no staked tokens.
    error NoTokensInTraining();

    /// @dev Thrown when the caller does not own a provided token ID.
    error TokenNotOwned();

    /* ------------------------------------------------------------------------------------------ */
    /*                                           STRUCTS                                          */
    /* ------------------------------------------------------------------------------------------ */

    struct TokenInfo {
        uint64 lastTimestamp;
        address owner;
        uint32 _empty_slot;
    }

    struct UserInfo {
        uint256[] ids;
        uint256 _empty_slot;
    }

    /* ------------------------------------------------------------------------------------------ */
    /*                                          FUNCTIONS                                         */
    /* ------------------------------------------------------------------------------------------ */

    /// @notice Returns the Serpenta contract address.
    function serpenta() external view returns (address);

    /// @notice Stakes tokens.
    /// @param ids The token IDs
    function enableTraining(uint256[] calldata ids) external;

    /// @notice Unstakes tokens.
    /// @dev Most efficient is to call with IDs in the opposite order of user's IDs since it's a stack.
    /// E.G.: user.ids == [1, 2, 3] -> disableTraining([3, 2, 1])
    /// @param ids The token IDs
    function disableTraining(uint256[] calldata ids) external;

    /// @notice Returns a user's tokens in training.
    /// @param user The user
    function getUserTokens(address user) external view returns (uint256[] memory);

    /// @notice Returns whether the provided tokens are in training.
    /// @param ids The token IDs
    function inTraining(uint256[] calldata ids) external view returns (bool[] memory);

    /// @notice Returns how long the provided tokens have been in training for.
    /// @param ids The token IDs
    function inTrainingFor(uint256[] calldata ids) external view returns (uint256[] memory);
}
