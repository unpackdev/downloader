// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ITEARSale {
    /// @dev Struct to keep track of each user's information
    struct User {
        address addr; // User's address
        uint256 amount; // Amount of ETH contributed by the user
    }

    /// @dev Sale flags
    enum SaleFlag {
        SALE_CLOSED,
        SALE_PRESALE,
        SALE_PUBLIC
    }

    /// @dev Retrieves user information by their ID
    /// @param idx The ID of the user
    /// @return User memory The user data structure containing the address and amount contributed
    function getUser(uint256 idx) external view returns (User memory);

    /// @dev Retrieves the user ID associated with a given address
    /// @param user The address of the user
    /// @return uint256 The user ID corresponding to the given address
    function getUserIdx(address user) external view returns (uint256);
}
