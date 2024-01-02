pragma solidity ^0.8.0;

interface IRouterConfig {
    function feeTo() external view returns (address);
    function crossChainFeeTo() external view returns (address);
}
