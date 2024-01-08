// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20SnapshotUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./PausableUpgradeable.sol";


contract WIFToken is 
    Initializable, ContextUpgradeable,
    AccessControlEnumerableUpgradeable, PausableUpgradeable, ERC20BurnableUpgradeable, 
    ERC20SnapshotUpgradeable, ERC20PermitUpgradeable 
{
    string constant NAME    = 'WhatIsFaster Token';
    string constant SYMBOL  = 'WIF';
    uint8 constant DECIMALS  = 18;
    uint256 constant INITIAL_SUPPLY = 24_000 * 10**uint256(DECIMALS);

    bytes32 public constant WHITELISTED_MSG_SENDER_ROLE = keccak256("WHITELISTED_MSG_SENDER_ROLE");
    bytes32 public constant WHITELISTED_FROM_ROLE = keccak256("WHITELISTED_FROM_ROLE");

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    constructor() {
        //Dummy call to initializer to prevent somebody to initialize instance
        __Context_init_unchained();
    }

    function initialize(address owner) public virtual initializer {
        __WIFToken_init(owner);
    }

    function __WIFToken_init(address owner) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained(NAME, SYMBOL);
        __ERC20Snapshot_init_unchained();
        __EIP712_init_unchained(NAME, "1");
        __ERC20Permit_init_unchained(NAME);
        __WIFToken_init_unchained(owner);
    }

    function __WIFToken_init_unchained(address owner) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);              // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(WHITELISTED_MSG_SENDER_ROLE, owner);     // Allows manual transfers
        _setupRole(WHITELISTED_FROM_ROLE, owner);           // Allows to interract with contracts
        _mint(owner, INITIAL_SUPPLY);
    }

    /**
     * @notice Triggers stopped state.
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Creates a new snapshot and returns its snapshot id.
     * @return id of created snapshot
     */
    function snapshot() external onlyAdmin returns(uint256) {
        return _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);

        require(
            !paused() ||                                    // unpaused mode
            hasRole(WHITELISTED_MSG_SENDER_ROLE, _msgSender()) ||      
            hasRole(WHITELISTED_FROM_ROLE, from),                      
            "transfers paused"
        );
    }

}
