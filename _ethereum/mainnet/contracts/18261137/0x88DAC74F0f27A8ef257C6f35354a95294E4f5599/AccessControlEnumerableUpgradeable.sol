// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./BitMapsUpgradeable.sol";
import "./IAccessControlEnumerableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is
    Initializable,
    IAccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /* solhint-disable no-empty-blocks */
    function __AccessControlEnumerable_init() internal onlyInitializing {}

    /* solhint-disable no-empty-blocks */
    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getRoleMembers(bytes32 role) external view virtual returns (address[] memory) {
        return _roleMembers[role].values();
    }

    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _getRoleMemberCount(role);
    }

    function _getRoleMemberCount(bytes32 role) internal view returns (uint256) {
        return _roleMembers[role].length();
    }

    function _grantRole(bytes32 role, address account) internal virtual override {
        if (role == DEFAULT_ADMIN_ROLE && _getRoleMemberCount(role) == 1) {
            revert AccessControlEnumerableUpgradeable__ExceedLimit();
        }
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    function _grantRoles(bytes32 role_, address[] calldata accounts_) internal {
        uint256 length = accounts_.length;

        for (uint256 i; i < length; ) {
            _grantRole(role_, accounts_[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _revokeRoles(bytes32 role_, address[] calldata accounts_) internal {
        uint256 length = accounts_.length;

        for (uint256 i; i < length; ) {
            _revokeRole(role_, accounts_[i]);
            unchecked {
                ++i;
            }
        }
    }

    uint256[49] private __gap;
}
