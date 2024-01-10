// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.5.0;

import "./Initializable.sol";
import "./Roles.sol";

 /**
 * @title Roles contract
 * @dev Base contract which allows children to implement role system.
 * - Users can:
 *   # Add event minter if Event Minter or Admin
 *   # Add Admin if Admin
 *   # Check if addr is Admin
 *   # Check if addr is Event Minter for Event ID
 *   # Renounce Admin role
 *   # Renounce Event Minter role
 *   # Remove Event Minter if Admin
 * @author POAP
 * - Developers:
 *   # Agustin Lavarello
 *   # Rodrigo Manuel Navarro Lajous
 *   # Ramiro Gonzales
 **/
contract PoapRoles is Initializable {
    using Roles for Roles.Role;

    /**
     * @dev Emmited when an Admin is added
     */
    event AdminAdded(address indexed account);

    /**
     * @dev Emmited when an Admin is removed
     */
    event AdminRemoved(address indexed account);
    
    /**
     * @dev Emmited when an Event Minter is added
     */
    event EventMinterAdded(uint256 indexed eventId, address indexed account);
    
    /**
     * @dev Emmited when an Event Minter is removed
     */
    event EventMinterRemoved(uint256 indexed eventId, address indexed account);

    Roles.Role private _admins;
    mapping(uint256 => Roles.Role) private _minters;

    function initialize(address sender) public initializer {
        if (!isAdmin(sender)) {
            _addAdmin(sender);
        }
    }

    /**
     * @dev Modifier to make a function callable only by the Admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Sender is not Admin");
        _;
    }

    /**
     * @dev Modifier to make a function callable only by the Event Minter for especific Event Id.
     * @param eventId ( uint256 ) The Event Id to check.
     */
    modifier onlyEventMinter(uint256 eventId) {
        require(isEventMinter(eventId, msg.sender), "Sender is not Event Minter");
        _;
    }

    /**
     * @dev Checks if address is Admin.
     * @param account ( address ) The address to be checked.
     * @return bool representing if the adddress is admin.
     */
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    /**
     * @dev Checks if address is Event Minter for especific Event.
     * @param eventId ( uint256 ) The Event ID to check.
     * @param account ( address ) The address to be checked.
     * @return bool representing if the adddress is Event Minter.
     */
    function isEventMinter(uint256 eventId, address account) public view returns (bool) {
        return isAdmin(account) || _minters[eventId].has(account);
    }

    /**
     * @dev Function to add an Event Minter for especefic Event ID
     * Requires 
     * - The msg sender to be the admin or Event Minter for the especific Event ID
     * @param eventId ( uint256 ) The ID of the Event.
     * @param account ( address ) The Address that will be granted permissions on the Event.
     */
    function addEventMinter(uint256 eventId, address account) public onlyEventMinter(eventId) {
        _addEventMinter(eventId, account);
    }

    /**
     * @dev Function to add an Admin.
     * Requires 
     * - The msg sender to be the admin.
     * @param account ( address ) The Address that will be granted permissions as Admin.
     */
    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    /**
     * @dev Function renounce as Event Minter for especefic Event ID
     * Requires 
     * - The msg sender to be an Event Minter for the especific Event ID
     * @param eventId ( uint256 ) The ID of the Event.
     */
    function renounceEventMinter(uint256 eventId) public {
        _removeEventMinter(eventId, msg.sender);
    }

    /**
     * @dev Function renounce as Admin
     * Requires 
     * - The msg sender to be an Admin
     */
    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    /**
     * @dev Function remove Event Minter for especif Event ID
     * Requires 
     * - The msg sender to be an Admin
     * @param eventId ( uint256 ) The ID of the Event.
     * @param account ( address ) The Address that will be removed permissions as Event Minter for especific ID.
     */
    function removeEventMinter(uint256 eventId, address account) public onlyAdmin {
        _removeEventMinter(eventId, account);
    }

    /**
     * @dev Internal function to add Event Minter
     * @param eventId ( uint256 ) The ID of the Event.
     * @param account ( address ) The Address that will be granted permissions on the Event.
     */
    function _addEventMinter(uint256 eventId, address account) internal {
        _minters[eventId].add(account);
        emit EventMinterAdded(eventId, account);
    }

    /**
     * @dev Internal function to add Admin
     * @param account ( address ) The Address that will be granted permissions as Admin.
     */
    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    /**
     * @dev Internal function to remove Event Minter for especif Event ID
     * @param eventId ( uint256 ) The ID of the Event.
     * @param account ( address ) The Address that will be removed permissions as Event Minter for especific ID.
     */
    function _removeEventMinter(uint256 eventId, address account) internal {
        _minters[eventId].remove(account);
        emit EventMinterRemoved(eventId, account);
    }

    /**
     * @dev Internal function to remove an Admin
     * @param account ( address ) The Address that will be removed permissions as Admin.
     */
    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }

    // For future extensions
    uint256[50] private ______gap;
}
