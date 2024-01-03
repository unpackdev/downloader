/**
 *Submitted for verification at Etherscan.io on 2020-10-11
*/

pragma solidity ^0.6.1;

contract Payout
{
address payable public address1 = 0x8dDd4c51a5dCfb83E070f04bF5C4F98b3FdA6977;
address payable public address2 = 0x2aAB156B5586FB0028a0Afe9250554317669ADcf;
address public owner = 0x482F222e30D49BF9606a0F6DEa7c210698B367F9;
	
uint256 public address1share = 8750;
uint256 public address2share = 1250;

uint256 public previousPayouts = 0;
uint256 public countPayouts = 0;

receive() external payable
{
	
}

function triggerPayouts() public
{
	uint totalPayout = address(this).balance;
	if(!address1.send(totalPayout * address1share / 100 / 100)) revert();
	if(!address2.send(totalPayout * address2share / 100 / 100)) revert();
	countPayouts += totalPayout;
}

function transferAllFundsOut(address payable _address) public
{
	if (msg.sender == owner)
		if(!_address.send(address(this).balance))
			revert();	
}

function totalPayouts() view public returns (uint256)
{
	return previousPayouts + countPayouts;
}
}