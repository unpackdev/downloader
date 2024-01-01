// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IAuthority.sol";

/**
 * @title Authority Whitelist smart contract
 * @notice this contract manages a whitelists for all the admins, borrowers and lenders
 */
contract Authority is OwnableUpgradeable, IAuthority {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event BorrowerAdded(address indexed actor, address indexed borrower);
    event BorrowerRemoved(address indexed actor, address indexed borrower);
    event LenderAdded(address indexed actor, address indexed lender);
    event LenderRemoved(address indexed actor, address indexed lender);
    event AdminAdded(address indexed actor, address indexed admin);
    event AdminRemoved(address indexed actor, address indexed admin);

    EnumerableSetUpgradeable.AddressSet whitelistedBorrowers;
    EnumerableSetUpgradeable.AddressSet whitelistedLenders;
    EnumerableSetUpgradeable.AddressSet admins;

    /**
     * @notice Restricts function execution to the contract owner or admins
     * @dev Throws an error if the caller is not the owner or admin
     */
    modifier onlyOwnerOrAdmin() {
        require(owner() == msg.sender || admins.contains(msg.sender), "Authority: caller is not the owner or admin");
        _;
    }

    /// @dev initializer
    function initialize() external initializer {
        __Ownable_init();
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice adds borrower address to the whitelist.
     * @param a address to add to the whitelist
     * @dev can only be called by the contract owner or admins
     */
    function addBorrower(address a) external onlyOwnerOrAdmin {
        if (whitelistedBorrowers.add(a)) {
            emit BorrowerAdded(msg.sender, a);
        }
    }

    /**
     * @notice removes borrower address from the whitelist.
     * @param a address to remove from the whitelist
     * @dev can only be called by the contract owner or admins
     */
    function removeBorrower(address a) external onlyOwnerOrAdmin {
        if (whitelistedBorrowers.remove(a)) {
            emit BorrowerRemoved(msg.sender, a);
        }
    }

    /**
     * @notice checks if the borrower address is in the whitelist.
     * @param a address to check
     * @return true if the address is in the whitelist
     */
    function isWhitelistedBorrower(address a) external view returns (bool) {
        return whitelistedBorrowers.contains(a);
    }

    /**
     * @notice returns array of all whitelisted borrower addresses
     *
     */
    function allBorrowers() external view returns (address[] memory) {
        return whitelistedBorrowers.values();
    }

    /**
     * @notice adds lenders address to the whitelist.
     * @param lender address to add to the whitelist
     */
    function addLender(address lender) external onlyOwnerOrAdmin {
        if (whitelistedLenders.add(lender)) {
            emit LenderAdded(msg.sender, lender);
        }
    }

    /**
     * @notice removes lenders address from the whitelist.
     * @param lender address to remove from the whitelist
     */
    function removeLender(address lender) external onlyOwnerOrAdmin {
        if (whitelistedLenders.remove(lender)) {
            emit LenderRemoved(msg.sender, lender);
        }
    }

    /**
     * @notice checks if the lender address is in the whitelist.
     * @param lender address to check
     * @return true if the address is in the whitelist
     */
    function isWhitelistedLender(address lender) external view returns (bool) {
        return whitelistedLenders.contains(lender);
    }

    /// @notice returns array of all whitelisted lender addresses
    function allLenders() external view returns (address[] memory) {
        return whitelistedLenders.values();
    }

    /**
     * @notice adds admin address to the list.
     * @param newAdmin address to add to the list
     */
    function addAdmin(address newAdmin) external onlyOwnerOrAdmin {
        if (admins.add(newAdmin)) {
            emit AdminAdded(msg.sender, newAdmin);
        }
    }

    /**
     * @notice removes admin address from the list.
     * @param admin address to remove from the list
     */
    function removeAdmin(address admin) external onlyOwnerOrAdmin {
        if (admins.remove(admin)) {
            emit AdminRemoved(msg.sender, admin);
        }
    }

    /**
     * @notice checks if the admin in the list.
     * @param a address to check
     * @return true if the address is in the list
     */
    function isAdmin(address a) external view returns (bool) {
        return admins.contains(a);
    }

    /**
     * @notice returns array of all admin addresses
     */
    function allAdmins() external view returns (address[] memory) {
        return admins.values();
    }
}
