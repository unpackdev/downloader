pragma solidity ^0.4.17;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract contractB {
  address tracker_0x_address = 0x6f259637dcD74C767781E37Bc6133cd6A68aa161; // ContractA Address
  mapping ( address => uint256 ) public balances;

  function deposit(uint tokens) public {

    // add the deposited tokens into existing balance 
    balances[msg.sender]+= tokens;

    // transfer the tokens from the sender to this contract
    ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
  }

  function returnTokens() public {
    balances[msg.sender] = 0;
    ERC20(tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
  }

}