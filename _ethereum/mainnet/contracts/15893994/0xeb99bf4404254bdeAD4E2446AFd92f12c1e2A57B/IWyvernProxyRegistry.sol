pragma solidity ^0.8.4;

interface IWyvernProxyRegistry {
    function proxies(address register) external returns (address);
}
