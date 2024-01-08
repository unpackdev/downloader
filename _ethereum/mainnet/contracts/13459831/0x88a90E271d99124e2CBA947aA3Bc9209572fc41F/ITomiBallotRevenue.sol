pragma solidity >=0.5.0;

interface ITomiBallotRevenue {
    function proposer() external view returns(address);
    function endTime() external view returns(uint);
    function executionTime() external view returns(uint);
    function end() external returns (bool);
    function total() external view returns(uint);
    function weight(address user) external view returns (uint);
    function participateByGovernor(address user) external;
}