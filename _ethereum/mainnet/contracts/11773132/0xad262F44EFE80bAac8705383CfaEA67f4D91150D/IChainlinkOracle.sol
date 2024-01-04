pragma solidity ^0.5.16;

interface IChainlinkOracle {
    function latestAnswer() external returns (int256);
}
