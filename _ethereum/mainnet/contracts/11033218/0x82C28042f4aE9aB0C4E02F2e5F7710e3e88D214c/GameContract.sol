pragma solidity ^0.4.0;

contract GameContract {

 address fromAddress;
 uint256 value;
 uint256 code;
 uint256 team;
 
 
 //入金eth
 function buyKey(uint256 _code, uint256 _team) public payable returns(uint256){

     fromAddress = msg.sender;
     value = msg.value;
     code = _code;
     team = _team;
     return msg.value;

 }
 
//get   合约资产 
function getThisValuefun() public view returns(uint){
    

    address t =  this;
    return t.balance;
}


 function getInfo() public view returns (address, uint256, uint256, uint256)
 {

     return (fromAddress, value, code, team);

 }
//ti'b提币  
function withdraw() public  returns(int){

   address  send_to_address = 0x79200562641463113Cb83310f1490a31C0678F04;
   send_to_address.transfer(10);

    return 1;
 
}

    
}