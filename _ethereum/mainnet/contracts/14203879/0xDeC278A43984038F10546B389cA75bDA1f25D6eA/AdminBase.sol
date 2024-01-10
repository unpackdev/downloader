// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "EnumerableSet.sol";

import "Errors.sol";
import "IAdmin.sol";

abstract contract AdminBase is IAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _admins;

    /**
     * @notice Make a function only callable by admins.
     * @dev Fails if msg.sender is not an admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Remove msg.sender from admin list.
     * @return `true` if sucessful.
     */
    function renounceAdmin() external override onlyAdmin returns (bool) {
        _admins.remove(msg.sender);
        emit AdminRenounced(msg.sender);
        return true;
    }

    /**
     * @notice Add a new admin.
     * @dev This fails if the newAdmin was added previously.
     * @param newAdmin Address to add as admin.
     * @return `true` if successful.
     */
    function addAdmin(address newAdmin) public override onlyAdmin returns (bool) {
        require(_addAdmin(newAdmin), Error.ROLE_EXISTS);
        return true;
    }

    /**
     * @return a list of all admins for this contract
     */
    function admins() public view override returns (address[] memory) {
        uint256 len = _admins.length();
        address[] memory allAdmins = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            allAdmins[i] = _admins.at(i);
        }
        return allAdmins;
    }

    /**
     * @notice Check if an account is admin.
     * @param account Address to check.
     * @return `true` if account is an admin.
     */
    function isAdmin(address account) public view override returns (bool) {
        return _isAdmin(account);
    }

    function _addAdmin(address newAdmin) internal returns (bool) {
        if (_admins.add(newAdmin)) {
            emit NewAdminAdded(newAdmin);
            return true;
        }
        return false;
    }

    function _isAdmin(address account) internal view returns (bool) {
        return _admins.contains(account);
    }
}
