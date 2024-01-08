// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";

/// @title Locked
/// @dev Smart contract to enable locking and unlocking of token holders. 
contract Locked is AccessControlEnumerableUpgradeable {

    mapping (address => bool) public lockedList;

    event AddedLock(address user);
    event RemovedLock(address user);

    // Create a new role identifier for the controller role
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

       modifier isController {
            require(hasRole(CONTROLLER_ROLE, msg.sender), "Locked::isController - Caller is not a controller");

        _;
    }

        modifier isMinter {
            require(hasRole(MINTER_ROLE, msg.sender), "Locked::isMinter - Caller is not a minter");
        _;
    }

    /// @dev terminate transaction if any of the participants is locked
    /// @param _from - user initiating process
    /// @param _to  - user involved in process
    modifier isNotLocked(address _from, address _to) {

        if (!hasRole(DEFAULT_ADMIN_ROLE, _from)){  // allow contract admin on sending tokens even if recipient is locked
            require(!lockedList[_from], "Locked::isNotLocked - User is locked");
            require(!lockedList[_to], "Locked::isNotLocked - User is locked");
        }
        _;
    }

    /// @dev check if user has been locked
    /// @param _user - usr to check
    /// @return true or false
    function isLocked(address _user) public view returns (bool) {
        return lockedList[_user];
    }
    
    /// @dev add user to lock
    /// @param _user to lock
    function addLock (address _user) public  isController() {        
        _addLock(_user);
    }

    function addLockMultiple(address[] memory _users) public isController() {
        uint256 length = _users.length;
        require(length <= 256, "Locked-addLockMultiple: List too long");
        for (uint256 i = 0; i < length; i++) {
            _addLock(_users[i]);
        }
    }

    /// @dev unlock user
    /// @param _user - user to unlock
    function removeLock (address _user) isController() public {       
        _removeLock(_user);
    }


    /// @dev add user to lock for internal needs
    /// @param _user to lock
    function _addLock(address _user) internal {
        lockedList[_user] = true;
        emit AddedLock(_user);
    }

    /// @dev unlock user for internal needs
    /// @param _user - user to unlock
    function _removeLock (address _user) internal {
        lockedList[_user] = false;
        emit RemovedLock(_user);
    }

}