// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./ICategories.sol";

contract Categories is ICategories, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private _set;

    function contains(bytes32 name) public view override returns (bool) {
        return _set.contains(name);
    }

    function length() public view override returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) public view override returns (bytes32) {
        return _set.at(index);
    }

    function values() public view override returns (bytes32[] memory) {
        return _set.values();
    }

    function add(bytes32 name) external override{
        require(!contains(name), "Name does not exist");
        _set.add(name);
        emit Added(name);
    }

    function remove(bytes32 name) external override{
        require(contains(name), "Name already exists");
        _set.remove(name);
        emit Removed(name);
    }
}
