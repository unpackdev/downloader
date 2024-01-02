// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./AddressResolverLib.sol";
import "./IAddressResolver.sol";
import "./IBeaconProxyController.sol";
import "./ICurrencyController.sol";
import "./IGenesisValueVault.sol";
import "./ILendingMarketController.sol";
import "./IReserveFund.sol";
import "./ITokenVault.sol";
import "./MixinAddressResolverStorage.sol";

contract MixinAddressResolver {
    event CacheUpdated(bytes32 name, address destination);

    error OnlyAcceptedContract(string name);
    error ResolverAlreadyRegistered();

    modifier onlyLendingMarketController() {
        if (msg.sender != address(AddressResolverLib.lendingMarketController()))
            revert OnlyAcceptedContract("LendingMarketController");
        _;
    }

    /**
     * @notice Returns the contract names used in this contract.
     * @dev The contract name list is in `./libraries/Contracts.sol`.
     */
    function requiredContracts() public pure virtual returns (bytes32[] memory contracts) {}

    function buildCache() public {
        // The resolver must call this function whenever it updates its state
        bytes32[] memory contractNames = requiredContracts();
        for (uint256 i; i < contractNames.length; i++) {
            bytes32 name = contractNames[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = Storage.slot().resolver.getAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            Storage.slot().addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    function isResolverCached() external view returns (bool) {
        bytes32[] memory contractNames = requiredContracts();
        for (uint256 i; i < contractNames.length; i++) {
            bytes32 name = contractNames[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (
                Storage.slot().resolver.getAddress(name) != Storage.slot().addressCache[name] ||
                Storage.slot().addressCache[name] == address(0)
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Register the Address Resolver contract
     * @param _resolver The address of the Address Resolver contract
     */
    function registerAddressResolver(address _resolver) internal {
        if (address(Storage.slot().resolver) != address(0)) revert ResolverAlreadyRegistered();
        Storage.slot().resolver = IAddressResolver(_resolver);
    }

    function getAddress(bytes32 name) internal view returns (address) {
        return AddressResolverLib.getAddress(name);
    }

    function resolver() public view returns (IAddressResolver) {
        return Storage.slot().resolver;
    }

    function beaconProxyController() internal view returns (IBeaconProxyController) {
        return AddressResolverLib.beaconProxyController();
    }

    function currencyController() internal view returns (ICurrencyController) {
        return AddressResolverLib.currencyController();
    }

    function genesisValueVault() internal view returns (IGenesisValueVault) {
        return AddressResolverLib.genesisValueVault();
    }

    function reserveFund() internal view returns (IReserveFund) {
        return AddressResolverLib.reserveFund();
    }

    function lendingMarketController() internal view returns (ILendingMarketController) {
        return AddressResolverLib.lendingMarketController();
    }

    function tokenVault() internal view returns (ITokenVault) {
        return AddressResolverLib.tokenVault();
    }
}
