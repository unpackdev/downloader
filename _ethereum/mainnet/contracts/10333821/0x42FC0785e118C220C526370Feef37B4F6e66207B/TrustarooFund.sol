pragma solidity ^0.4.0;

// @Smart Contract: TrustarooFund
// @Author: Trustaroo Global Community Fund - TGCF

contract TrustarooFund {
    
    address public owner;
    uint public total;
    
    mapping (address => uint) public invested;
    mapping (address => uint) public balances;
    
    address[] investors;

	function TrustarooFund() public {
		owner = msg.sender;
	}

    // Fund Manager Fee
    
    function ownerFee(uint amount) private returns (uint fee) {
        
        fee = amount / 10;
        balances[owner] += fee;

        return;
        
    }

    function withdraw() public
    {
        require( balances[msg.sender] != 0 );

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        if ( !msg.sender.send(amount) ) {
            balances[msg.sender] = amount;
        }
        
    }

    // Fallback to Accept Funds
    
	function () public payable
    {
        uint dividend = msg.value;

        // First Investment Goes Completely to the Fund Manager.
        
        if (investors.length == 0) {
            balances[owner] = msg.value;
        } else {
            
            uint fee = ownerFee(dividend);

            dividend -= fee;
            
        }
     
         // Distribute Dividends
         for ( uint i = 0; i < investors.length; i++ ) {
           if (balances[investors[i]] == 0) {
                balances[investors[i]] = dividend * invested[investors[i]] / total;
           } else {
               balances[investors[i]] += dividend * invested[investors[i]] / total;
           }
         }

        if ( invested[msg.sender] == 0 ) {
            investors.push(msg.sender);
            invested[msg.sender] = msg.value;
        } else {
            invested[msg.sender] += msg.value;
        }

        total += msg.value;
        
	}
}