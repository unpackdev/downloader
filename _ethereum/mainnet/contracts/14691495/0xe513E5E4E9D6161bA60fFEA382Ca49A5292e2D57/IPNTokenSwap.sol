//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPNTokenSwap{
    function getV1TokenAddress() external view returns(address);
    function getV2TokenAddress() external view returns(address); 
    function getV1TokenTaker() external view returns(address);   
    function setV1TokenTaker(address _newTokenTaker) external; 
    function swap(uint256 amount) external;
}