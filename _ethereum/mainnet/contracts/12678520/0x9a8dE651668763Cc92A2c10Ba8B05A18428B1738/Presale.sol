// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";


contract Presale is Ownable, ReentrancyGuard  {
	using Address for address;

	// token
	IERC20 token;

	bool public isSaleActive = false;

	uint256 public totalTokensSold = 0;

	//0.5 ETH = 500 millionen gwei, 5e24 = 5 Million Tokens, taking decimals into consideration
	uint256 public purchaseamount = 500e6 gwei;
	uint256 public tokensToReceive = 5e24;

	struct buydata { 
		address receiver;
		uint256 amount;
	}

	buydata [] public buyers;

	event TokenBuy(address user, uint256 tokens);

	constructor (address _tokenAddress)  {
		token = IERC20(_tokenAddress);
	}

	receive() external payable {
		buy (msg.sender);
	}  

	function buy (address _buyer) public payable nonReentrant {
		require(isSaleActive, "Sale is not active yet");
		
		buydata memory buyer;
			
		//calculate tokens to receive;
		uint256 _ETHSent = msg.value;

		//checks
		require(_ETHSent == purchaseamount, "not the right amount of ETH has been sent");	

		totalTokensSold += tokensToReceive;
		require(totalTokensSold <= token.balanceOf(address(this)), "no tokens left");

		buyer.receiver = msg.sender;
		buyer.amount = tokensToReceive;

		buyers.push(buyer);

		emit TokenBuy(_buyer, tokensToReceive);
	}

	function getTokensLeft () external view returns (uint256) {
		return token.balanceOf(address(this)) - totalTokensSold;
	}

	function startSale() external onlyOwner {
		isSaleActive = true;
	}

	function stopSale() external onlyOwner {
		isSaleActive = false;
		//sent everyone their tokens
		for (uint256 index = 0; index < buyers.length; index++) {
			token.transfer(buyers[index].receiver, buyers[index].amount);
		}
		//withdraw everything
		withdrawFunds();
		withdrawUnsoldTokens();

		//reset
		delete buyers;
	}

	function withdrawFunds () public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function withdrawUnsoldTokens() public onlyOwner {
		token.transfer(owner(), token.balanceOf(address(this)));
	}
}