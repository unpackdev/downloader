pragma solidity 0.8.18;

import "./Ownable.sol";

/**
 * @title Admin
 * @notice Allows contract owner to add/remove admins
 */
contract Admin is Ownable {
    // Mapping of admin to whether it is an admin
    mapping(address => bool) private _admins;
    // Number of admins
    uint32 private _adminCount;

    // ============ Events ============
    /**
     * @notice Emitted when an admin is added
     * @param admin address of the admin
     */
    event AdminAdded(address admin);
    /**
     * @notice Emitted when an admin is removed
     * @param admin address of the admin
     */
    event AdminRemoved(address admin);

    // Errors
    error NotAdmin();
    error InvalidAdminAddress();
    error AlreadyAdmin();
    error CannotRemoveLastAdmin();

    // ============ Modifiers ============
    /**
     * @dev Throws if called by any account other than the admin
     */
    modifier onlyAdmin() {
        if (!isAdmin(msg.sender)) {
            revert NotAdmin();
        }
        _;
    }

    // ============ Constructor ============
    /**
     * @notice Initializes the contract
     * set the deployer as the first admin
     */
    constructor() {
        addAdmin(msg.sender);
    }

    // ============ Functions ============
    /**
     * @notice Adds an admin
     */
    function addAdmin(address account) public onlyOwner {
        if (account == address(0)) {
            revert InvalidAdminAddress();
        }
        if (isAdmin(account)) {
            revert AlreadyAdmin();
        }
        _admins[account] = true;
        _adminCount += 1;
        emit AdminAdded(account);
    }

    /**
     * @notice Removes an admin when there is more than one admin
     */
    function removeAdmin(address account) public onlyOwner {
        if (_adminCount == 1) {
            revert CannotRemoveLastAdmin();
        }

        if (!isAdmin(account)) {
            revert NotAdmin();
        }

        _admins[account] = false;
        _adminCount -= 1;
        emit AdminRemoved(account);
    }

    /**
     * @notice Returns whether an account is an admin
     * @param account address of the account
     * @return bool true if account is an admin
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }
} 