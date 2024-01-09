// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

import "./Ownable.sol";

import "./IWhitelist.sol";


/// @title Whitelist 
/// @dev Whitelist authentication
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract Whitelist is Ownable, IWhitelist {
    

    /// Whitelist
    mapping (address => bool) internal list;


    /// @dev Add `_accounts` to the whitelist
    /// @param _accounts The accounts to add
    function add(address[] calldata _accounts) override public onlyOwner {
        for (uint i = 0; i < _accounts.length; i++) {
            list[_accounts[i]] = true;
        }
    }


    /// @dev Remove `_accounts` from the whitelist
    /// @param _accounts The accounts to remove
    function remove(address[] calldata _accounts) override public onlyOwner {
       for (uint i = 0; i < _accounts.length; i++) {
            list[_accounts[i]] = false;
        }
    }

    /// @dev Authenticate 
    /// Returns whether `_account` is on the whitelist
    /// @param _account The account to authenticate
    /// @return whether `_account` is successfully authenticated
    function authenticate(address _account) override public view returns (bool) {
        return list[_account];
    }
}