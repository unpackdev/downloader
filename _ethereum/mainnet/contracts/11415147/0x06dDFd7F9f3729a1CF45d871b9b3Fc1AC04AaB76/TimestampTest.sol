pragma solidity 0.7.4;

contract TimestampTest {
    uint256 public lastCalledTimestamp;
    uint256 public lastPredictedTimestamp;
    
    function call(uint256 predictedTimestamp) external {
        lastCalledTimestamp = block.timestamp;
        lastPredictedTimestamp = predictedTimestamp;
    }
}