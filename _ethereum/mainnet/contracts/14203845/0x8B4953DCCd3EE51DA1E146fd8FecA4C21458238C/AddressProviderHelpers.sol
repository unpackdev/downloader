// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "IGasBank.sol";
import "IVaultReserve.sol";
import "IOracleProvider.sol";
import "IAddressProvider.sol";

import "AddressProviderKeys.sol";

library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The gas bank.
     */
    function getGasBank(IAddressProvider provider) internal view returns (IGasBank) {
        return IGasBank(provider.getAddress(AddressProviderKeys._GAS_BANK_KEY));
    }

    /**
     * @return The address of the vault reserve.
     */
    function getVaultReserve(IAddressProvider provider) internal view returns (IVaultReserve) {
        return IVaultReserve(provider.getAddress(AddressProviderKeys._VAULT_RESERVE_KEY));
    }

    /**
     * @return The address of the swapperRegistry.
     */
    function getSwapperRegistry(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._SWAPPER_REGISTRY_KEY);
    }

    /**
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }
}
