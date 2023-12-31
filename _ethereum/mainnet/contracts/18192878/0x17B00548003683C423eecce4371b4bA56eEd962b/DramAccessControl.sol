// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./IDramAccessControl.sol";
import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./StringsUpgradeable.sol";

/**
 * @notice Role based access control contract to manage Dram's protected functions
 */
abstract contract DramAccessControl is
    Initializable,
    IDramAccessControl,
    ContextUpgradeable,
    ERC165Upgradeable
{
    mapping(bytes32 => mapping(address => bool)) private _roles;

    address private _currentAdmin;
    address private _pendingAdmin;

    /**
     * @notice Admin is the most powerful role which is responsible for managing other roles.
     * Admin also have access to the highly protected functions.
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /**
     * @notice Role manager is also responsible for managing roles (except admin role).
     * Role manager can set the minting cap for the supply manager role.
     */
    bytes32 public constant ROLE_MANAGER_ROLE = keccak256("ROLE_MANAGER_ROLE");
    /**
     * @notice Supply manager is responsible for minting and burning Dram tokens.
     */
    bytes32 public constant SUPPLY_MANAGER_ROLE =
        keccak256("SUPPLY_MANAGER_ROLE");
    /**
     * @notice Regulatory manager is responsible for freezing and pausing functionalities.
     */
    bytes32 public constant REGULATORY_MANAGER_ROLE =
        keccak256("REGULATORY_MANAGER_ROLE");

    /**
     * @dev A modifier to check if the current msg.seder has the required role.
     * Role must be the result of keccak256.
     * @param role The role that needs to be checked for the caller
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev Like onlyRole but bypasses the check if the msg.sender is the admin.
     */
    modifier onlyRoleOrAdmin(bytes32 role) {
        _checkRoleOrAdmin(role);
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __DramAccessControl_init(
        address admin,
        address roleManager,
        address supplyManager,
        address regulatoryManager
    ) internal onlyInitializing {
        __DramAccessControl_init_unchained(
            admin,
            roleManager,
            supplyManager,
            regulatoryManager
        );
    }

    // solhint-disable-next-line func-name-mixedcase
    function __DramAccessControl_init_unchained(
        address admin,
        address roleManager,
        address supplyManager,
        address regulatoryManager
    ) internal onlyInitializing {
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(ROLE_MANAGER_ROLE, roleManager);
        _grantRole(SUPPLY_MANAGER_ROLE, supplyManager);
        _grantRole(REGULATORY_MANAGER_ROLE, regulatoryManager);
    }

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDramAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function hasRole(
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
        return _roles[role][account];
    }

    /**
     * @dev Calls the _checkRole with msg.sender as account.
     * @param role The role that needs to be checked
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Like _checkRole but bypasses the check if the caller is admin.
     * @param role The role that needs to be checked
     */
    function _checkRoleOrAdmin(bytes32 role) internal view virtual {
        if (!hasRole(ADMIN_ROLE, _msgSender())) {
            _checkRole(role, _msgSender());
        }
    }

    /**
     * @dev Calls hasRole with role and account and throws error if the result is false.
     * @param role The role that needs to be checked
     * @param account Address that needs to have the required role
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert MissingRoleError(role, account);
        }
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function grantRole(
        bytes32 role,
        address account
    ) external virtual override onlyRoleOrAdmin(ROLE_MANAGER_ROLE) {
        if (role == ADMIN_ROLE) revert DirectAdminUpdateError();
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external virtual override onlyRoleOrAdmin(ROLE_MANAGER_ROLE) {
        if (role == ADMIN_ROLE) revert DirectAdminUpdateError();
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function renounceRole(
        bytes32 role,
        address account
    ) external virtual override {
        if (role == ADMIN_ROLE) revert DirectAdminUpdateError();
        if (account != _msgSender()) revert NotSelfError();
        _revokeRole(role, _msgSender());
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function transferAdminRole(
        address newAdmin
    ) external virtual onlyRole(ADMIN_ROLE) {
        if (newAdmin == address(0) || newAdmin == _msgSender())
            revert InvalidAdminTransferError();
        _currentAdmin = _msgSender();
        _pendingAdmin = newAdmin;
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function acceptAdminRoleTransfer() external virtual {
        if (_pendingAdmin != _msgSender()) revert NotPendingAdminError();
        _revokeRole(ADMIN_ROLE, _currentAdmin);
        _grantRole(ADMIN_ROLE, _pendingAdmin);
        _deleteAdminTransfer();
        emit AdminRoleTransferred(_currentAdmin, _pendingAdmin);
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function getAdminRoleTransferInfo()
        external
        view
        virtual
        returns (address currentAdmin, address pendingAdmin)
    {
        currentAdmin = _currentAdmin;
        pendingAdmin = _pendingAdmin;
    }

    /**
     * @inheritdoc IDramAccessControl
     */
    function cancelAdminTransfer() external onlyRole(ADMIN_ROLE) {
        _deleteAdminTransfer();
    }

    /**
     * @dev Implementation of the role granting process as an internal function so that
     * other contract functions can call the logic directly without worrying about modifiers.
     * @param role The role to be granted
     * @param account Address that will have the role
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Implementation of the role revoking process as an internal function so that
     * other contract functions can call the logic directly without worrying about modifiers.
     * @param role The role to be revoked
     * @param account Address that won't have the role anymore
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev finishes or cancels the admin transferring process by deleting the states.
     */
    function _deleteAdminTransfer() internal virtual {
        delete _currentAdmin;
        delete _pendingAdmin;
    }

    uint256[47] private __gap;
}
