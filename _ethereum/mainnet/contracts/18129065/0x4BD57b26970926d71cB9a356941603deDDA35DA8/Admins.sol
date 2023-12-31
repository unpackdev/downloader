// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) and a project leader that can grant exclusive access to
 * specific functions.
 */
abstract contract Admins is Ownable {
    address public projectLeader;
    address[] public admins;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error AdminsUnauthorizedAccount(address account);

    event ProjectLeaderTransferred(address indexed previousLead, address indexed newLead);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        projectLeader = initialOwner;
    }

     /**
    @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    @dev Internal function to check if the sender is an admin.
    */
    function _checkAdmins() internal view virtual {
        if (!checkIfAdmin()) {
            revert AdminsUnauthorizedAccount(_msgSender());
        }
    }

    /**
    @dev Checks if the sender is an admin.
    @return bool indicating whether the sender is an admin or not.
    */
    function checkIfAdmin() public view virtual returns(bool) {
        if (_msgSender() == owner() || _msgSender() == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(_msgSender() == admins[i]){
                    return true;
                }
            }
        }
        // Not an Admin
        return false;
    }

    /**
    @dev Owner and Project Leader can set the addresses as approved Admins.
    Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public virtual onlyAdmins {
        if (_msgSender() != owner() || _msgSender() != projectLeader) {
            revert AdminsUnauthorizedAccount(_msgSender());
        }
        delete admins;
        admins = _users;
    }

    /**
    @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) public virtual onlyAdmins {
        if (_msgSender() != owner() || _msgSender() != projectLeader) {
            revert AdminsUnauthorizedAccount(_msgSender());
        }
        address oldPL = projectLeader;
        projectLeader = _user;
        emit ProjectLeaderTransferred(oldPL, _user);
    }
}
