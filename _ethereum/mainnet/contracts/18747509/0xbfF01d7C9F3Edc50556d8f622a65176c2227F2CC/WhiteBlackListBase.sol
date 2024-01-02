// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ERC165Upgradeable.sol";
import "./IAccessControlUpgradeable.sol";
import "./IERC165Upgradeable.sol";

import "./Errors.sol";

import "./Constants.sol";
import "./IWhiteBlackList.sol";

abstract contract WhiteBlackListBase is IWhiteBlackList, ERC165Upgradeable {
    mapping(address => AccessType) internal accessList;
    address public override registry;

    //to new variables without shifting down storage in the inheritance chain.
    uint256[50] private __gap;

    /**
     * @dev Throws if caller is not granted with _role
     * @param _role The role that is being checked for a function caller
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControlUpgradeable(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    function isBlackListed(address _address) external view override returns (bool) {
        return accessList[_address] == AccessType.BLACKLISTED;
    }

    function addAddressesToWhitelist(address[] calldata _addresses) public override {
        for (uint256 i; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

    function removeAddressFromWhitelist(address _address) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(accessList[_address] == AccessType.WHITELISTED, Errors.ADDRESS_NOT_WHITELISTED.selector);
        accessList[_address] = AccessType.UNLISTED;
        emit WhitelistedAddressRemoved(_address);
    }

    function removeAddressesFromWhitelist(address[] calldata _addresses) public override {
        for (uint256 i; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }

    function addAddressesToBlacklist(address[] calldata _addresses) public override {
        for (uint256 i; i < _addresses.length; i++) {
            addAddressToBlacklist(_addresses[i]);
        }
    }

    function removeAddressFromBlacklist(address _address) public override onlyRole(SMALL_TIMELOCK_ADMIN) {
        _require(accessList[_address] == AccessType.BLACKLISTED, Errors.ADDRESS_NOT_BLACKLISTED.selector);
        accessList[_address] = AccessType.UNLISTED;
        emit BlacklistedAddressRemoved(_address);
    }

    function removeAddressesFromBlacklist(
        address[] calldata _addresses
    ) public override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        for (uint256 i; i < _addresses.length; i++) {
            removeAddressFromBlacklist(_addresses[i]);
        }
    }

    /**
     * @param _address The address to add to blacklist
     */
    function addAddressToBlacklist(address _address) public virtual override;

    /**
     * @param _address The address to add to whitelist
     */
    function addAddressToWhitelist(address _address) public virtual override;

    /**
     *
     * @param _address The address to check on its AccessType
     */
    function getAccessType(address _address) public view override returns (AccessType) {
        return accessList[_address];
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IWhiteBlackList).interfaceId || super.supportsInterface(_interfaceId);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __WhiteBlackListBase_init(address _registry) internal onlyInitializing {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControlUpgradeable).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
        __ERC165_init();
    }

    function _addAddressToBlacklist(address _address) internal {
        _require(accessList[_address] != AccessType.BLACKLISTED, Errors.ADDRESS_ALREADY_BLACKLISTED.selector);
        accessList[_address] = AccessType.BLACKLISTED;
        emit BlacklistedAddressAdded(_address);
    }

    function _addAddressToWhitelist(address _address) internal {
        _require(accessList[_address] != AccessType.WHITELISTED, Errors.ADDRESS_ALREADY_WHITELISTED.selector);
        accessList[_address] = AccessType.WHITELISTED;
        emit WhitelistedAddressAdded(_address);
    }
}
