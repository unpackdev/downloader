// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./AccessControlEnumerableUpgradeable.sol";

contract Controllable is AccessControlEnumerableUpgradeable {
    // keccak256('OPERATOR')
    bytes32 private constant _OPERATOR_ROLE =
        0x523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c;

    mapping(address => uint8) internal _accountStatus;

    function __Controllable_init_unchained(
        address account
    ) internal onlyInitializing {
        __AccessControl_init();
        _setRoleAdmin(_OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, account);
        _grantRole(_OPERATOR_ROLE, account);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Restricted to Admins.");
        _;
    }

    /// @dev Restricted to members of the Operator role.
    modifier onlyOperator() {
        require(isOperator(_msgSender()), "Restricted to Operators.");
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the operator role.
    function isOperator(address account) public view returns (bool) {
        return hasRole(_OPERATOR_ROLE, account);
    }

    /// @dev Add an account to the operator role. Restricted to admins.
    function addOperator(address account) external onlyAdmin {
        _grantRole(_OPERATOR_ROLE, account);
    }

    /// @dev Remove an account from the Operator role. Restricted to admins.
    function removeOperator(address account) external onlyAdmin {
        _revokeRole(_OPERATOR_ROLE, account);
    }

    /// @dev Remove oneself from the Admin role thus all other roles.
    function renounceAdmin() external {
        address sender = _msgSender();
        renounceRole(DEFAULT_ADMIN_ROLE, sender);
        renounceRole(_OPERATOR_ROLE, sender);
    }

    /// @dev Remove oneself from the Operator role.
    function renounceOperator() external {
        renounceRole(_OPERATOR_ROLE, _msgSender());
    }

    uint256[50] private __gap;
}
