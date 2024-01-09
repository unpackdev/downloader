// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Roles.sol";

contract DaoRole is Context {
    using Roles for Roles.Role;

    event DaoAdded(address indexed account);
    event DaoRemoved(address indexed account);

    Roles.Role private _daos;

    constructor () {
        _addDao(_msgSender());
    }

    modifier onlyDao() {
        require(isDao(_msgSender()), "DaoRole: caller does not have the Dao role");
        _;
    }

    function isDao(address account) public view returns (bool) {
        return _daos.has(account);
    }

    function addDao(address account) public onlyDao {
        _addDao(account);
    }

    function renounceDao() public {
        _removeDao(_msgSender());
    }

    function _addDao(address account) internal {
        _daos.add(account);
        emit DaoAdded(account);
    }

    function _removeDao(address account) internal {
        _daos.remove(account);
        emit DaoRemoved(account);
    }
}