// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract Address {
    /**
        Verifies that the address is not null
    */
    modifier isValidAddress(address _address) {
        assert(_address != address(0));
        _;
    }

    /**
        Verifies that the address does not match the one provided
    */
    modifier isNotAddress(address _address, address _restricted) {
        assert(_address != _restricted);
        _;
    }
}