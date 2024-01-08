// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPAYR.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract Crowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

	uint256 constant fundingGoal = 125 * (10**18);
	/* how much has been raised by crowdale (in ETH) */
	uint256 public amountRaised;
	/* how much has been raised by crowdale (in PAYR) */
	uint256 public amountRaisedPAYR;

	/* the start & end date of the crowdsale */
	uint256 public start;
	uint256 public deadline;
	uint256 public publishDate;

	/* there are different prices in different time intervals */
	uint256 constant price = 192000;

	/* the address of the token contract */
	IPAYR private tokenReward;
	/* the balances (in ETH) of all investors */
	mapping(address => uint256) public balanceOf;
	/* the balances (in PAYR) of all investors */
	mapping(address => uint256) public balanceOfPAYR;
	/* indicates if the crowdsale has been closed already */
	bool public saleClosed = false;
	/* notifying transfers and the success of the crowdsale*/
	event GoalReached(address beneficiary, uint256 amountRaised);
	event FundTransfer(address backer, uint256 amount, bool isContribution, uint256 amountRaised);

    /*  initialization, set the token address */
    constructor(IPAYR _token, uint256 _start, uint256 _dead, uint256 _publish) {
        tokenReward = _token;
		start = _start;
		deadline = _dead;
		publishDate = _publish;
    }

    /* invest by sending ether to the contract. */
    receive () external payable {
		if(msg.sender != owner()) //do not trigger investment if the multisig wallet is returning the funds
        	invest();
		else revert();
    }

	function updateDeadline(uint256 _dead, uint256 _publish) external onlyOwner {
		deadline = _dead;
		publishDate = _publish;
	}

	function checkFunds(address addr) external view returns (uint256) {
		return balanceOf[addr];
	}

	function checkPAYRFunds(address addr) external view returns (uint256) {
		return balanceOfPAYR[addr];
	}

	function getETHBalance() external view returns (uint256) {
		return address(this).balance;
	}

    /* make an investment
    *  only callable if the crowdsale started and hasn't been closed already and the maxGoal wasn't reached yet.
    *  the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
    *  the sent value is directly forwarded to a safe multisig wallet.
    *  this method allows to purchase tokens in behalf of another address.*/
    function invest() public payable {
    	uint256 amount = msg.value;
		require(saleClosed == false && block.timestamp >= start && block.timestamp < deadline, "sale-closed");
		require(msg.value >= 10**17, "less than 0.1 ETH");
		require(balanceOf[msg.sender] <= 5 * 10**18, "more than 5 ETH");

		balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);

		amountRaised = amountRaised.add(amount);

		balanceOfPAYR[msg.sender] = balanceOfPAYR[msg.sender].add(amount.mul(price));
		amountRaisedPAYR = amountRaisedPAYR.add(amount.mul(price));

		if (amountRaised >= fundingGoal) {
			saleClosed = true;
			emit GoalReached(msg.sender, amountRaised);
		}
		
        emit FundTransfer(msg.sender, amount, true, amountRaised);
    }

    modifier afterClosed() {
        require(block.timestamp >= publishDate, "sale-in-progress");
        _;
    }

	function getPAYR() external afterClosed nonReentrant {
		require(balanceOfPAYR[msg.sender] > 0, "non-contribution");
		uint256 amount = balanceOfPAYR[msg.sender];
		uint256 balance = tokenReward.balanceOf(address(this));
		require(balance >= amount, "lack of funds");
		balanceOfPAYR[msg.sender] = 0;
		tokenReward.transfer(msg.sender, amount);
	}

	function withdrawETH() external onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0, "zero-balance");
		address payable payableOwner = payable(owner());
		payableOwner.transfer(balance);
	}

	function withdrawPAYR() external onlyOwner {
		uint256 balance = tokenReward.balanceOf(address(this));
		require(balance > 0, "zero-payr-balance");
		tokenReward.transfer(owner(), balance);
	}
}