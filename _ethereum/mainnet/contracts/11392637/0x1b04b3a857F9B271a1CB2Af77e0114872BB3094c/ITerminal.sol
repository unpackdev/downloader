pragma solidity ^0.6.2;

interface ITerminal {
    function calculateRewards(uint, uint) external pure returns(uint256);
    function getRewardsPerBlock() external view returns (uint256);
    function mint(address, uint) external;
    function burn(address, uint) external;
}