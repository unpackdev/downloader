// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./AccessControl.sol";
import "./ICoreAccessControlV1.sol";
import "./DefinitiveErrors.sol";

struct CoreAccessControlConfig {
    address admin;
    address definitiveAdmin;
    address[] definitive;
    address[] client;
}

abstract contract CoreAccessControl is ICoreAccessControlV1, OZAccessControl {
    // roles
    bytes32 public constant ROLE_DEFINITIVE = keccak256("DEFINITIVE");
    bytes32 public constant ROLE_DEFINITIVE_ADMIN = keccak256("DEFINITIVE_ADMIN");
    bytes32 public constant ROLE_CLIENT = keccak256("CLIENT");

    modifier onlyDefinitive() {
        _checkRole(ROLE_DEFINITIVE);
        _;
    }
    modifier onlyDefinitiveAdmin() {
        _checkRole(ROLE_DEFINITIVE_ADMIN);
        _;
    }
    modifier onlyClients() {
        _checkRole(ROLE_CLIENT);
        _;
    }
    modifier onlyClientAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }
    // default admin + definitive admin
    modifier onlyAdmins() {
        bool isAdmins = (hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(ROLE_DEFINITIVE_ADMIN, _msgSender()));

        if (!isAdmins) {
            revert AccountNotAdmin(_msgSender());
        }
        _;
    }
    // client + definitive
    modifier onlyWhitelisted() {
        bool isWhitelisted = (hasRole(ROLE_CLIENT, _msgSender()) || hasRole(ROLE_DEFINITIVE, _msgSender()));

        if (!isWhitelisted) {
            revert AccountNotWhitelisted(_msgSender());
        }
        _;
    }

    constructor(CoreAccessControlConfig memory cfg) {
        // admin
        _setupRole(DEFAULT_ADMIN_ROLE, cfg.admin);

        // definitive admin
        _setupRole(ROLE_DEFINITIVE_ADMIN, cfg.definitiveAdmin);
        _setRoleAdmin(ROLE_DEFINITIVE_ADMIN, ROLE_DEFINITIVE_ADMIN);

        // definitive
        uint256 cfgDefinitiveLength = cfg.definitive.length;
        for (uint256 i; i < cfgDefinitiveLength; ) {
            _setupRole(ROLE_DEFINITIVE, cfg.definitive[i]);
            unchecked {
                ++i;
            }
        }
        _setRoleAdmin(ROLE_DEFINITIVE, ROLE_DEFINITIVE_ADMIN);

        // clients - implicit role admin is DEFAULT_ADMIN_ROLE
        uint256 cfgClientLength = cfg.client.length;
        for (uint256 i; i < cfgClientLength; ) {
            _setupRole(ROLE_CLIENT, cfg.client[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _checkRole(bytes32 role, address account) internal view virtual override {
        if (!hasRole(role, account)) {
            revert AccountMissingRole(account, role);
        }
    }
}
