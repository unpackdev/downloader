pragma solidity ^0.8.0;

interface IxTokenManager {
    function isManager(address fund, address caller) external view returns (bool);
}
