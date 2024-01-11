// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBlacklist {

    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    
    function add(address account) external returns(bool);
    function remove(address account) external returns(bool);
    function isBlacklisted(address account)external returns(bool);
}