// contracts/TGE.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
// import "./Ownable.sol";


contract TGE is Ownable{
    event deposit(address Investor, uint Investment);
    
    address payable public TGEwallet;
    
    mapping(address => uint) public balances;

    constructor(address owner) {
        TGEwallet = payable(owner);
    }

    function Invest() payable public{
        require((msg.value >= 0.01 ether && msg.value <= 0.5 ether));
        balances[msg.sender] += msg.value;
        emit deposit(msg.sender, msg.value);

    }
    function CollectFunds() public payable onlyOwner {
        
        TGEwallet.transfer(address(this).balance);
    }
    
    function FundsAccured() public view returns(uint){
        return address(this).balance;
    }
    
    function getInvestment(address Investor) public view returns(uint){
        return balances[Investor];
    }
    
    function EndTGE() public onlyOwner{
        selfdestruct(TGEwallet);
    }
}