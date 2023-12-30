pragma solidity ^0.5.17;

contract BlockNumberHelper {
    
    function getBlockNumber() external view returns (uint256) {
        return block.number;
    }
    
}