pragma solidity ^0.6.0;

contract shareHelper {
    function getChainId() external pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}