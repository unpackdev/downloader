pragma solidity ^0.4.22;

 interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}
contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;//管理员地址
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * @param  newOwner address
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
contract ETHtoBET is Ownable{
    uint public ethPoint;
    tokenTransfer public bebTokenTransfer; //BET合约地址
    constructor(address _tokenAddress) public {
        bebTokenTransfer = tokenTransfer(_tokenAddress);//0x2ceea562a32e78f37f1244641320049a7d1fb72a
        ethPoint=70 ether;
    }
    function buy(uint _eth)payable public{
        require(_eth>ethPoint);
        uint _value=msg.value* 1 ether/_eth;
        bebTokenTransfer.transfer(msg.sender,_value);
    }
    function buyADmin(uint _eth)onlyOwner{
        ethPoint=_eth;
    }
    function withdrawal(address _addr,uint256 amount) onlyOwner{
       //uint256 _amount=amount* 10 ** 18;
       require(owner==msg.sender);
       _addr.transfer(amount);//取款BEB
    }
     function withdrawalBET(address _addr,uint256 amount) onlyOwner{
       //uint256 _amount=amount* 10 ** 18;
       require(owner==msg.sender);
       bebTokenTransfer.transfer(_addr,amount);//取款ETH
    }
    function ()payable{
        
    }
    
}