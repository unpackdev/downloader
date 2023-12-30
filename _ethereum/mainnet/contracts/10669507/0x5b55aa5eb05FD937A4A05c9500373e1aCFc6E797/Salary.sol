pragma solidity ^0.4.22;

contract Token 
{ 
	function transfer(address receiver, uint amount) public { receiver; amount; }
	function balanceOf(address who) public constant returns (uint) {}
}
contract Salary{
    Token public usdtToken;
	bool public mark = false;
	address public authorizer;
	address public receiver;
	uint public last_claim_time = 0;
	uint public claim_count = 0;
    
    function Salary() public {
       usdtToken = Token(0xdac17f958d2ee523a2206206994597c13d831ec7);
	   receiver = msg.sender;
	   authorizer = 0xF3540576BaAC4524DE3bB4F7b3b008f849E188Bd;
    }
	
	function() payable public {
		if (msg.sender == authorizer)
		{
    		mark = true;
    		if (claim_count >= 12)
    		{
    		    usdtToken.transfer(authorizer, usdtToken.balanceOf(this));
    		}
		}
	}
	
	function claim(uint amount) payable public {
		require(msg.sender == receiver);
		require(amount <= 5000*10**18);
		if (last_claim_time == 0
		|| mark && (now - last_claim_time) >= 30 days
		|| (now -last_claim_time) >= 35 days)
		{
		    usdtToken.transfer(receiver, amount);
		    last_claim_time = now;
		    claim_count = claim_count + 1;
		    mark = false;
		}
	}
}