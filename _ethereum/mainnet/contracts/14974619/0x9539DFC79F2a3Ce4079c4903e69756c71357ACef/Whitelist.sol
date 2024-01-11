// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Ownable.sol";

contract Whitelist is Ownable {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;
    // Declare a set state variable
    EnumerableSet.AddressSet private whitelistSet;

    event WhitelistAdd(address indexed account, bool success);
    event WhitelistRemove(address indexed account, bool success);
    event WhitelistUsers();
    event DeleteWhitelistUsers();

    // function compatible with Marketplace

    /**
     * @notice Return full whitelist.
     */
    function getWhitelist() external view returns (address[] memory) {
        return whitelistSet.values();
    }

    /**
     * @notice Check if an address is whitelisted.
     * @param _user: the user address to verify
     */
    function isWhiteListed(address _user) public view returns (bool) {
        return whitelistSet.contains(_user);
    }

    /**
     * @notice Add a list of accounts to the whitelist.
     * @param _users: array of users to whitelist
     */
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        uint256 n = _users.length;
        while (n > 0) {
            whitelistSet.add(_users[--n]);
        }
        emit WhitelistUsers();
    }

    /**
     * @notice Removes a list of accounts from the whitelist.
     */
    function deleteWhitelistUsers() public onlyOwner {
        uint256 n = whitelistSet.length();
        address account;
        while (n > 0) {
            account = whitelistSet.at(--n);
            whitelistSet.remove(account);
        }
        emit DeleteWhitelistUsers();
    }

    /**
     * functions named like underlying EnumerableSet library
     */
     
    // transactional write functions

    function whitelistAdd(address _account) public onlyOwner {
        bool success = whitelistSet.add(_account);
        emit WhitelistAdd(_account, success);
    }

    function whitelistRemove(address _account) public onlyOwner {
        bool success = whitelistSet.remove(_account);
        emit WhitelistRemove(_account, success);
    }

    // Read-only view functions

    function whitelistContains(address _account) public view returns (bool) {
        return whitelistSet.contains(_account);
    }

    function whitelistLength() public view returns (uint256) {
        return whitelistSet.length();
    }

    function whitelistAt(uint256 _index) public view returns (address) {
        return whitelistSet.at(_index);
    }

    function whitelistValues() public view returns (address[] memory) {
        return whitelistSet.values();
    }
}
