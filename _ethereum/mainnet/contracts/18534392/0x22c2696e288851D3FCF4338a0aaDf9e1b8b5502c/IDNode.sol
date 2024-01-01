// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDNode{
    function getRelations(address _address) external view returns(uint8 , address[] memory);
    function setDaoReward(uint256 _amount) external;
    function mint(address spender, uint256 amount) external  returns (bool);
}
