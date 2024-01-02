// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./IAddressResolver.sol";
import "./Ownable.sol";
import "./Proxyable.sol";
import "./AddressResolverStorage.sol";

/**
 * @notice Implements the logic to manage the contract addresses.
 *
 * This contract store the contract name and contract address. When the contract calls other contracts,
 * the caller contract gets the contract address from this contract.
 * However, the contract addresses are cashed into the caller contract through the `MixinAddressResolver.sol` at the deployment,
 * so the caller doesn't need to call this contract each time it calls other contracts.
 *
 * @dev This contract is used through the `./mixins/MixinAddressResolver.sol`. The names of the contracts that
 * need to be imported into this contract are managed in `./libraries/Contracts.sol`.
 */
contract AddressResolver is IAddressResolver, Ownable, Proxyable {
    /**
     * @notice Initializes the contract.
     * @dev Function is invoked by the proxy contract when the contract is added to the ProxyController.
     * @param _owner The address of the contract owner
     */
    function initialize(address _owner) public initializer onlyProxy {
        _transferOwnership(_owner);
    }

    /**
     * @notice Imports contract addresses.
     * @dev All addresses in the contract are overridden by `_addresses` in the argument.
     */
    function importAddresses(
        bytes32[] memory _names,
        address[] memory _addresses
    ) public onlyOwner {
        if (_names.length != _addresses.length) revert UnmatchedInputs();

        bytes32[] memory currentNames = Storage.slot().nameCaches;

        for (uint256 i; i < currentNames.length; i++) {
            Storage.slot().addresses[currentNames[i]] = address(0);
        }

        Storage.slot().nameCaches = _names;
        Storage.slot().addressCaches = _addresses;

        for (uint256 i; i < _names.length; i++) {
            bytes32 name = _names[i];
            address destination = _addresses[i];
            Storage.slot().addresses[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /**
     * @notice Gets if the addresses are imported.
     * @return The boolean if the addresses are imported or not
     */
    function areAddressesImported(
        bytes32[] calldata _names,
        address[] calldata _addresses
    ) external view returns (bool) {
        for (uint256 i; i < _names.length; i++) {
            if (Storage.slot().addresses[_names[i]] != _addresses[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Gets the imported contract addresses for the name with error.
     * @dev This method is used when the caller need to get an error if the address in the name
     * is not imported.
     * @return The contract address
     */
    function getAddress(
        bytes32 _name,
        string calldata _reason
    ) external view override returns (address) {
        address _foundAddress = Storage.slot().addresses[_name];
        if (_foundAddress == address(0)) revert(_reason);
        return _foundAddress;
    }

    /**
     * @notice Gets the imported contract addresses for the name.
     * @dev This method is used when the caller doesn't need to get an error if the address in the name
     * is not imported.
     * @return The contract address
     */
    function getAddress(bytes32 _name) external view override returns (address) {
        return Storage.slot().addresses[_name];
    }

    /**
     * @notice Gets the all imported contract addresses.
     * @return Array with the contract address
     */
    function getAddresses() external view override returns (address[] memory) {
        return Storage.slot().addressCaches;
    }

    /**
     * @notice Gets the all imported contract names.
     * @return Array with the contract address
     */
    function getNames() external view override returns (bytes32[] memory) {
        return Storage.slot().nameCaches;
    }
}
