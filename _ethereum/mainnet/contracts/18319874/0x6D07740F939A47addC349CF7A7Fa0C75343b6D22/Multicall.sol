/**
 *Submitted for verification at FtmScan.com on 2023-06-08
*/

pragma solidity ^0.8.0;

interface IContract {
    function getValue() external view returns (uint256);
}

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }


    struct Return {
      bool success;
      bytes data;

    }
    function aggregate(Call[] memory calls, bool strict) public view returns (uint256 blockNumber, Return[] memory returnData) {
        blockNumber = block.number;
        returnData = new Return[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.staticcall(calls[i].callData);
            if (strict) {
              require(success);
            }
            returnData[i] = Return(success, ret);
        }
    }
}