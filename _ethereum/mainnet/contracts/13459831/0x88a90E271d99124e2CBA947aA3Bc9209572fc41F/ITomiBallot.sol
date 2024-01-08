pragma solidity >=0.5.0;

interface ITomiBallot {
    function proposer() external view returns(address);
    function endTime() external view returns(uint);
    function executionTime() external view returns(uint);
    function value() external view returns(uint);
    function result() external view returns(bool);
    function end() external returns (bool);
    function total() external view returns(uint);
    function weight(address user) external view returns (uint);
    function voteByGovernor(address user, uint256 proposal) external;
}