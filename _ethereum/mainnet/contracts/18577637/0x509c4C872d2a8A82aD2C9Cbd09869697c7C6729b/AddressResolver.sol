pragma solidity ^0.8.20;

interface AddressResolver {
    function getAddress(bytes32 name) external view returns (address);
}