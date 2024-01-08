// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./AccessControlInitializer.sol";
import "./Adam721.sol";


contract Adam721Factory is AccessControl, AccessControlInitializer {
    event Adam721Created(address indexed operator, address indexed token, bytes32 indexed hashedSymbol, string symbol);
    event OperationCalled(address indexed operator, bytes32 indexed hashedOperation, string operation, address[] tokens);

    bytes32 public constant TOKEN_CREATOR_ROLE = keccak256("TOKEN_CREATOR_ROLE");
    bytes32 public constant TOKEN_GRANTER_ROLE = keccak256("TOKEN_GRANTER_ROLE");
    bytes32 public constant TOKEN_BASE_URI_SETTER_ROLE = keccak256("TOKEN_BASE_URI_SETTER_ROLE");

    constructor(bytes32[] memory roles, address[] memory addresses) {
        _setupRoleBatch(roles, addresses);
    }

    function createToken(
        string memory name, string memory symbol, string memory baseURI, bytes32[] memory roles, address[] memory addresses
    ) public virtual onlyRole(TOKEN_CREATOR_ROLE) returns (address) {
        Adam721 adam721 = new Adam721(name, symbol, baseURI, roles, addresses);
        emit Adam721Created(_msgSender(), address(adam721), keccak256(bytes(symbol)), symbol);
        return address(adam721);
    }

    function grantRoleTokenBatch(
        address[] memory adam721s, bytes32[] memory roles, address[] memory addresses
    ) public virtual onlyRole(TOKEN_GRANTER_ROLE) {
        require(roles.length == addresses.length, "Adam721Factory: roles and addresses length mismatch");

        for (uint i = 0; i < adam721s.length; i++) {
            Adam721 adam721 = Adam721(adam721s[i]);
            for (uint j = 0; j < addresses.length; j++) {
                require(addresses[j] != address(0), "Adam721Factory: grant to the zero address");
                if (! adam721.hasRole(roles[j], addresses[j])) {
                    adam721.grantRole(roles[j], addresses[j]);
                }
            }
        }

        // keccak256("grantRoleTokenBatch") = 0xe23df3e3d59990d1bc93f7edf7351a2a96feca3d3477dbca6b8e9d9365b0e654
        emit OperationCalled(_msgSender(), keccak256("grantRoleTokenBatch"), "grantRoleTokenBatch", adam721s);
    }

    function revokeRoleTokenBatch(
        address[] memory adam721s, bytes32[] memory roles, address[] memory addresses
    ) public virtual onlyRole(TOKEN_GRANTER_ROLE) {
        require(roles.length == addresses.length, "Adam721Factory: roles and addresses length mismatch");

        for (uint i = 0; i < adam721s.length; i++) {
            Adam721 adam721 = Adam721(adam721s[i]);
            for (uint j = 0; j < addresses.length; j++) {
                if (adam721.hasRole(roles[j], addresses[j])) {
                    adam721.revokeRole(roles[j], addresses[j]);
                }
            }
        }

        // keccak256("revokeRoleTokenBatch") = 0xc0d205a90c3521ca3035042709caae41075b3746af5e0e54907206052a6f6891
        emit OperationCalled(_msgSender(), keccak256("revokeRoleTokenBatch"), "revokeRoleTokenBatch", adam721s);
    }

    function setBaseURITokenBatch(
        address[] memory adam721s, string memory newValue
    ) public virtual onlyRole(TOKEN_BASE_URI_SETTER_ROLE) {
        for (uint i = 0; i < adam721s.length; i++) {
            Adam721(adam721s[i]).setBaseTokenURI(newValue);
        }

        // keccak256("setBaseURITokenBatch") = 0x89f7df486d526b1499393110d9d50bd4c450d188fd43830084979a81ac328453
        emit OperationCalled(_msgSender(), keccak256("setBaseURITokenBatch"), "setBaseURITokenBatch", adam721s);
    }
}
