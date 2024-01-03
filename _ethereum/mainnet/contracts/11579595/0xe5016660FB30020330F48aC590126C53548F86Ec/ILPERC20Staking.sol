pragma solidity 0.6.12; 

interface ILPERC20Staking {
    function epochCalculationStartBlock() external returns(uint);
    function addPendingRewards() external;
    function startNewEpoch() external;

}