pragma solidity ^0.6.0;

interface IMinimalBPool {
    function resyncWeights(address up, address down) external;
}
