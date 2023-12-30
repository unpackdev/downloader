pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

contract Multicall {
    bytes constant internal MULTICALL_FAIL = abi.encodePacked(keccak256('MULTICALL_FAIL'));
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            if (success) {
              returnData[i] = ret;
            } else {
              returnData[i] = MULTICALL_FAIL;
            }
        }
    }
}