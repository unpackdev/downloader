// File: contracts/AddressChecker.sol


pragma solidity ^0.8.9;

contract AddressChecker {
    function isContract(address account) external view returns (bool) {
        return account.code.length > 0;
    }
}