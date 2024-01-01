//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    
    function fundTransfer(uint256 proposalId, address _proposeeAdd, uint256 ethAmount) external;

    function distributeProfit(uint256 proposalId, uint256 pirateId, uint256 _lendingAmount,uint256 _refundAmount) external payable;

    function getExpectedPirateToken(uint _amount) external view returns(uint);

    function getExpectedEth(uint _amount) external view returns(uint);

}