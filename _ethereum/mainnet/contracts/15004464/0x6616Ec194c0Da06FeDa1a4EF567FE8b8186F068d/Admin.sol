pragma solidity 0.8.10;
//SPDX-License-Identifier: MIT


/** @title Admin contract  */
/// @author Paladin
contract Admin {

    /** @notice (Admin) Event when the contract admin is updated */
    event NewAdmin(address oldAdmin, address newAdmin);

    /** @notice (Admin) Event when the contract pendingAdmin is updated */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /** @dev Admin address for this contract */
    address public admin;

    /** @dev Pending admin address for this contract */
    address public pendingAdmin;
    
    modifier adminOnly() {
        //allows only the admin of this contract to call the function
        if(msg.sender!= admin) revert CallerNotAdmin();
        _;
    }

    error CallerNotAdmin();
    error CannotBeAdmin();
    error CallerNotpendingAdmin();
    error AdminZeroAddress();

    constructor() {
        admin = msg.sender;
    }

    
    function transferAdmin(address newAdmin) external adminOnly {
        if(newAdmin == address(0)) revert AdminZeroAddress();
        if(newAdmin == admin) revert CannotBeAdmin();
        address oldPendingAdmin = pendingAdmin;

        pendingAdmin = newAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newAdmin);
    }

    function acceptAdmin() external {
        if(pendingAdmin == address(0)) revert AdminZeroAddress();
        if(msg.sender != pendingAdmin) revert CallerNotpendingAdmin();
        address newAdmin = pendingAdmin;
        address oldAdmin = admin;
        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);

        pendingAdmin = address(0);

        emit NewPendingAdmin(newAdmin, address(0));
    }
}