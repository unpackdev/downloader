// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./OwnableUpgradeable.sol";

/// @title AddressManager
/// @notice Only owners of this contract can edit the addresses held.
/// @dev This contract is used for addresses holding reserve assets needed to be read by Chainlink nodes for the proof
/// of reserve system.
contract AddressManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    enum Network {
        CARDANO_TESTNET,
        DOGE_TESTNET,
        CARDANO_MAINNET,
        DOGE_MAINNET
    }

    mapping(Network => string[]) public walletAddressesMap;

    /// @dev Public function to read the network name
    /// @param network An enum for the network string
    function networkName(Network network)
        external
        pure
        returns (string memory name)
    {
        if (network == Network.CARDANO_MAINNET) name = "Cardano Mainnet";
        if (network == Network.CARDANO_TESTNET) name = "Cardano Testnet";
        if (network == Network.DOGE_MAINNET) name = "Doge Mainnet";
        if (network == Network.DOGE_TESTNET) name = "Doge Testnet";
    }

    /// @notice This method can only be called once for a unique contract address
    /// @dev Initialization for the token, here only the owner is set
    function initialize(address owner) external virtual initializer {
        __Ownable_init();
        OwnableUpgradeable.transferOwnership(owner);
    }

    /// @dev Public function to add an address to the list of those holding collateral in reserve
    /// @param network The network the address holds reserves in
    /// @param addr Address that will be added to the list for a network
    function addWalletAddress(Network network, string memory addr)
        external
        onlyOwner
    {
        walletAddressesMap[network].push(addr);
    }

    /// @dev Public function to update the address of the code contract
    /// @param network The network the address holds reserves in
    /// @param index Position of the address in the list
    function removeWalletAddress(Network network, uint256 index)
        external
        onlyOwner
    {
        string[] storage addressList = walletAddressesMap[network];

        uint256 length = addressList.length;
        require(index < length, "invalid address item");

        uint256 lastIndex = length - 1;
        addressList[index] = addressList[lastIndex];

        addressList.pop();
    }

    /// @dev Public function to retrieve all the address holding reserve for a specified network
    /// @param network The enum representing a specific network
    function walletAddresses(Network network)
        external
        view
        returns (string[] memory)
    {
        return walletAddressesMap[network];
    }

    /// @dev Overrides the parent hook which is called ahead of upgrading the implementation address for this contract
    /// @param newImplementation new implementation contract address
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    uint256[49] private __gap;
}
