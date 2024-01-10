//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IOracle.sol";
import "./Ownable.sol";

contract TimestampVRF is Ownable{

    IOracle Oracle;

    uint nonce;

    constructor(address oracleAddress){
        Oracle = IOracle(oracleAddress);
    }

    function setOracle(address oracleAddress) external onlyOwner{
        Oracle = IOracle(oracleAddress);
    }

    function getCurrentIndex() external view returns(uint){
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
       // return Oracle.getTimestampCountById(tellorId);
        return 5;
    } 

    function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint){
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
        // uint result = Oracle.getTimestampCountById(tellorId);
        // uint tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,result-1);
        // if(tellorTimeStamp<_timestamp){
        //     return uint(keccak256(abi.encodePacked(_tokenId,block.timestamp/5 minutes)));
        // }
        // for(uint i=(result-2);i>0;i--){
        //     if(tellorTimeStamp < _timestamp)
        //     break;
        //     tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,i);
        // }
        // bytes memory tellorValue = Oracle.getValueByTimestamp(tellorId,tellorTimeStamp);
        return uint(keccak256(abi.encodePacked(_tokenId,block.timestamp/5 minutes)));
    }

}