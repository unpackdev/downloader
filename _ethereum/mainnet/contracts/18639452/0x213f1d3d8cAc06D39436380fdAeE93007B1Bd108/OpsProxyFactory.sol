pragma solidity ^0.8.20;

interface OpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);

    function deployFor(address owner) external returns (address payable proxy);

    function ops() external returns (address);
}