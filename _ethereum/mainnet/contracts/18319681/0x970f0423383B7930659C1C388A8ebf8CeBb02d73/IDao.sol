//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDao {
   
    function getBlackistedProposal(uint _deityId) external view returns(uint); 

    function getActiveProposal(uint _deityId) external view returns(uint); 

    function getDeityWaitingTime(uint _deityId) external view returns(uint); 

    function createProposal(uint256 deityId, address payable recipient, string memory projectName, string memory description, uint256 value, uint256 refundTime, uint startTime, uint endTime) external returns (uint256);

    function vote(uint256 proposalId, bool voteFor) external;

    function getVotedforProposal(address _voter, uint256 _proposalId) external view returns (int);

    function getProposalAmount(uint proposalId) external view returns(uint);

    function executeProposal(uint256 proposalId) external;

    function settlementFund(uint256 _proposalId) external  payable;

    function proposeJudgment(uint256 _proposalId, uint deityId, string calldata explanation, uint votingTime) external;

    function explainJudgment(string calldata _explanation, uint _deityId) external;

    function voteJudgment(uint _proposalId, bool _favourJudment) external;

    function processJudgment(uint256 _proposalId) external;

    function unlockBlacklistDeity(uint _deityId) external;

    function getRefundAmount(uint proposalId) external view returns(uint);

    function getJudgementAmount(uint proposalId) external view returns(uint);

} 