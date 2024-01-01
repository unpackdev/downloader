pragma solidity ^0.8.20;

interface OpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}