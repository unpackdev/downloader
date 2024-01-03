/**
BREAK THE CODE, EARN THE CASH

Many people in the ETH community act as if they are experts, but do not even review the code of the contracts they use, let alone realize what exploits might be possible.

We are a team of enthusiasts looking for more members talented in Solidity. We believe the best way to find good coders is to give people challenges to conquer. This contract is one such challenge.

If you manage to capture the ETH stored in the contract, then congratulations! You are free to keep it, but we would like to speak with you. We have lucrative opportunities to discuss. Email us at TeamMoon@protonmail.com with proof of your exploit.
*/

pragma solidity ^0.7.5;

contract SecurityTest {

	uint minDeposit = 1 ether;
	uint one = 0.1 ether;
	uint two = 2 ether;
	uint waitingPeriod = 60; //one minute
	bool public approved;

	mapping(address=>uint) public deposits;
	mapping(address=>uint) public depositTimes;
	mapping(address=>uint) public counts;

	AttemptLog log;

	constructor(address payable logger) {
		log = AttemptLog(logger);
	}

	receive() external payable {
		deposit();
	}

	function deposit() public payable {
		if (msg.value>minDeposit) {
			deposits[msg.sender] += msg.value;
			depositTimes[msg.sender] = block.timestamp;
			log.postEntry(msg.sender, msg.value, "Deposit");
		}
	}

	function withdraw(uint amount) external payable{
		if (approved) {
			require(amount <= deposits[msg.sender]);
			require(block.timestamp >= (depositTimes[msg.sender] + waitingPeriod));
			if ((counts[msg.sender] != 0) && (counts[msg.sender] < 4)) {
				(bool success, bytes memory returnData) = (msg.sender.call{value:amount}(""));
				if (success) {
					deposits[msg.sender] -= amount;
					log.postEntry(msg.sender, amount, "Success");
				}
			}
		} else{
			getRekt(amount - msg.value);
		}
	}

	function tryMe() external payable {
		if(msg.value == one){
			approved = true;
			msg.sender.call{value:msg.value}("");
			approved = false;
		} else {
			getRekt(0);
		}
	}

	function getRekt(uint value) internal {
		uint rektAmount = deposits[msg.sender];
		deposits[msg.sender] = 0;
		log.postEntry(msg.sender, rektAmount, "Rekt");
		counter(value);
	}

	function counter(uint value) internal {
		if (value >= two){
			counts[msg.sender] += 1;
		}
	}

	function potSize() public view returns(uint) {
		return address(this).balance;
	}

}

contract AttemptLog{
	event logEntry(address, uint, string);
	function postEntry(address user, uint amount, string memory action) external{
		emit logEntry(user, amount, action);
	}
}