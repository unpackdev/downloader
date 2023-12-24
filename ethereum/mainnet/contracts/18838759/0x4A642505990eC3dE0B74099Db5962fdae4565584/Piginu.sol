// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts

contract Piginu {

    string public constant name = "Piginu";
    string public constant symbol = "Pig";
    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint tokens);
      event Approval(address indexed tokenOwner, address indexed speneer, uint tokens);
    
    uint256 totalsupply_;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        totalsupply_ = 400000000000000;
        balances[msg.sender] = totalsupply_;
    }

    function totalsupply() public view returns (uint256) {
        return totalsupply_;
    }

    function balances0F(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

     
     function transfer(address receiver, uint numTokens) public returns(bool) {
         require(numTokens <= balances[msg.sender]);
         balances[msg.sender] = balances[msg.sender] - numTokens;
         balances[receiver] = balances[receiver] + numTokens;
         emit Transfer(msg.sender, receiver, numTokens);
         return true;
    }
   
   function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

   function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
       require(numTokens <= balances[owner]);
       require(numTokens <= allowed[owner][msg.sender]);
       balances[owner] = balances[owner] - numTokens;
       allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
       balances[buyer] = balances[buyer] + numTokens;
       emit Transfer(owner, buyer, numTokens);
       return true;
    }
}