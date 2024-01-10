//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IVRF{

    function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint);

    function getCurrentIndex() external view returns(uint); 
    
}