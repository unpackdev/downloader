pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

library LibSmartWallet {
    /// @dev define the diamond storage namespace
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("smartwallet.module.library");

    /// @dev We utilize a struct to store state
    /// @dev DO NOT STORE STRUCT IN STRUCTS
    struct SmartWalletFactoryState {
        mapping(address=>address) userWalletMap;
        mapping(address=>address) walletUserMap;
    }

    /// @dev returns the starting position of the storage slot from the namespace
    function diamondStorage()
        internal
        pure
        returns (SmartWalletFactoryState storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @dev saves the user to smartWallet key pair and reverse key pair
    function setUserWallet(address user, address wallet) internal {
        SmartWalletFactoryState storage smartWalletFactoryState = diamondStorage();
        smartWalletFactoryState.userWalletMap[user] = wallet;
        smartWalletFactoryState.walletUserMap[wallet] = user;
    }

    /// @dev gets the user address given a smartwallet address
    function getUserFromWallet(address wallet) internal view returns (address) {
        SmartWalletFactoryState storage smartWalletFactoryState = diamondStorage();
        return smartWalletFactoryState.walletUserMap[wallet];
    }

    /// @dev gets the smartwallet address given a user address
    function getWalletFromuser(address user) internal view returns(address) {
        SmartWalletFactoryState storage smartWalletFactoryState = diamondStorage();
        return smartWalletFactoryState.userWalletMap[user];
    }
}