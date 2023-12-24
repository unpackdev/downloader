// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./OwnableUpgradeable.sol";

import "./IWhitelist.sol";

/// @title Whitelist 
/// @dev Whitelist authentication
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract Whitelist is OwnableUpgradeable, IWhitelist {
    

    /// Whitelist
    mapping (address => bool) internal list;


    /**
     * Public Functions
     */
    function initialize(address[] memory accounts) public initializer 
    {
        __Ownable_init();
        for (uint i = 0; i < accounts.length; i++) {
            list[accounts[i]] = true;
        }
    }


    /// @dev Add `accounts` to the whitelist
    /// @param accounts The accounts to add
    function add(address[] memory accounts) override public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            list[accounts[i]] = true;
        }
    }


    /// @dev Remove `accounts` from the whitelist
    /// @param accounts The accounts to remove
    function remove(address[] memory accounts) override public onlyOwner {
       for (uint i = 0; i < accounts.length; i++) {
            list[accounts[i]] = false;
        }
    }

    /// @dev Authenticate 
    /// Returns whether `_account` is on the whitelist
    /// @param account The account to authenticate
    /// @return whether `_account` is successfully authenticated
    function authenticate(address account) override public view returns (bool) {
        return list[account];
    }
}