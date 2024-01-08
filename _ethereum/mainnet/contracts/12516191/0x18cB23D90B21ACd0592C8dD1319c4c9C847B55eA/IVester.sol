pragma solidity >=0.5.0;

interface IVester {
	function segments() external pure returns (uint);
	function vestingAmount() external pure returns (uint);
	function vestingBegin() external pure returns (uint);
	function vestingEnd() external pure returns (uint);
}