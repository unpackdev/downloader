// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface Finance {
    function deposit(
        address _token,
        uint256 _value,
        string memory _reference
    ) external payable;
}
