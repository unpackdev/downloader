// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Ownable.sol";
import "./EnumerableSet.sol";


contract FodlBoatliftersList is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private addresses;

    constructor(address[] memory _addresses) Ownable() {
        addAll(_addresses);
    }

    function getAll() public view returns (address[] memory) {
        return addresses.values();
    }

    function set(address[] memory _addresses) public onlyOwner {
       removeAll(getAll());
       addAll(_addresses);
    }

    function addAll(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++)
            add(_addresses[i]);
    }

    function add(address _address) public onlyOwner {
        addresses.add(_address);
    }

    function removeAll(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++)
            remove(_addresses[i]);
    }

    function remove(address _address) public onlyOwner {
       addresses.remove(_address);
    }
}