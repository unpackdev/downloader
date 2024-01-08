pragma solidity 0.6.2;

interface IMooniswapPoolGovernance {
    function feeVote(uint256 vote) external;
    function slippageFeeVote(uint256 vote) external;
    function decayPeriodVote(uint256 vote) external;
}