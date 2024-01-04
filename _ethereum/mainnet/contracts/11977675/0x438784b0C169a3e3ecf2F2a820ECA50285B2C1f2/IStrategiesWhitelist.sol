pragma solidity 0.6.6;

interface IStrategiesWhitelist {
    function isWhitelisted(address _allocationStrategy) external returns (uint8 answer);
}