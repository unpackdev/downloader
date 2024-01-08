pragma solidity =0.6.6;

interface IClaimable {
	function claim() external returns (uint amount);
	event Claim(address indexed account, uint amount);
}