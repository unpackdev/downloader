// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/

/** Thrown if at least one user is in the blocklist during the transfer process */
error blocklisted();

/** Thrown if the token constract is paused and user is not whitelisted */
error tokenPaused();

/**
    @title Unlimit Stablecoin
*/
contract UnlimitToken is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    /** The public identifier for Admin Role */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /** The public identifier for Minter Role */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /** The public identifier for Upgrader Role */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /** Whitelisted users who can transfer tokens when it's paused */
    mapping(address => bool) public whitelist;

    /** Blocklisted users who cannot receive and transfer tokens */
    mapping(address => bool) public blocklist;

    /** An event emitted when a whitelist status updated for some user */
    event WhitelistUpdated(address user, bool status);

    /** An event emitted when a blocklist status updated for some user */
    event BlocklistUpdated(address user, bool status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name,
        string calldata symbol
    ) public initializer {
        __ERC20_init(name, symbol);
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();

        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    /** Triggers stopped state. */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /** Returns to normal state. */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
        Issue new tokens to specific address. Available only for caller with Minter Role
        @param to - the address to which the new tokens will be minted
        @param amount - amount of tokens to be minted
    */

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
        Burn tokens from specific address. Available only for caller with Minter Role
        @param from - the address from which the tokens will be burned
        @param amount - amount of tokens to be burned
    */

    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(from, amount);
    }

    /**
        Updates whitelist status for user.
        @param user - user whose status is being changed
        @param status - new status
    */
    function updateWhitelist(
        address user,
        bool status
    ) external onlyRole(ADMIN_ROLE) {
        if (blocklist[user] && status) revert blocklisted();
        whitelist[user] = status;

        emit WhitelistUpdated(user, status);
    }

    /**
        Updates blocklist status for user.
        @param user - user whose status is being changed
        @param status - new status
    */
    function updateBlocklist(
        address user,
        bool status
    ) external onlyRole(ADMIN_ROLE) {
        blocklist[user] = status;

        emit BlocklistUpdated(user, status);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (blocklist[from] || blocklist[to] || blocklist[msg.sender])
            revert blocklisted();

        if (paused()) {
            if (!whitelist[from] || !whitelist[to] || !whitelist[msg.sender])
                revert tokenPaused();
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    uint256[50] private __gap;
}
