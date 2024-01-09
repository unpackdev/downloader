pragma solidity 0.7.6;

interface ISwapContract {
    function getActiveNodes() external returns (bytes32[] memory);
}
