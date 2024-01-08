pragma solidity 0.6.2;

interface IExchangeGovernance {
    function leftoverShareVote(uint256 govShare, uint256 refShare) external;
}