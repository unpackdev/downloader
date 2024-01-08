//SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./IAddressRegistry.sol";
import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract AddressRegistry is IAddressRegistry, Initializable, AccessControl {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (AddressTypes => EnumerableSet.AddressSet) private addressSets;

    EnumerableSet.AddressSet private tokenAddresses;
    EnumerableSet.AddressSet private controllerAddresses;
    EnumerableSet.AddressSet private poolAddresses;

    bytes32 public constant REGISTERED_ADDRESS = keccak256("REGISTERED_ROLE");

    modifier onlyRegistered () {
        require(hasRole(REGISTERED_ADDRESS, msg.sender), "NOT_REGISTERED");
        _;
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REGISTERED_ADDRESS, _msgSender());

        addressSets[AddressTypes.Token] = tokenAddresses;
        addressSets[AddressTypes.Controller] = controllerAddresses;
        addressSets[AddressTypes.Pool] = poolAddresses;
    }

    function addRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        grantRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressAdded(_addr);
    }

    function removeRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        revokeRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressRemoved(_addr);
    }

    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        EnumerableSet.AddressSet storage structToAddTo = addressSets[_index];

        for (uint256 i = 0; i < arrayLength; i++) {
            require(_addresses[i] != address(0), "INVALID_ADDRESS");
            structToAddTo.add(_addresses[i]);
        }

        emit AddedToRegistry(_addresses, _index);
    }

    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        EnumerableSet.AddressSet storage structToRemoveFrom = addressSets[_index];
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        require(arrayLength <= structToRemoveFrom.length(), "TOO_MANY_ADDRESSES");

        for (uint256 i = 0; i < arrayLength; i++) {
            address currentAddress = _addresses[i];
            require(structToRemoveFrom.contains(currentAddress), "DOES_NOT_EXIST");
            structToRemoveFrom.remove(currentAddress);
        }

        emit RemovedFromRegistry(_addresses, _index);
    }

    function getAddressForType(AddressTypes _index) external view override returns (address[] memory) {
        EnumerableSet.AddressSet storage structToReturn = addressSets[_index];
        uint256 arrayLength = structToReturn.length();

        address[] memory registryAddresses = new address[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            registryAddresses[i] = structToReturn.at(i);
        }
        return registryAddresses;
    }

    function checkAddress(address _addr, uint256 _index) external view override returns (bool) {
        EnumerableSet.AddressSet storage structToCheck = addressSets[AddressTypes(_index)];
        return structToCheck.contains(_addr);
    }
}