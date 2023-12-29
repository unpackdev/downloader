pragma solidity 0.4.25;

contract mile{

     function receiveEther() payable public{
     }

     function sendEther(address _address) payable public{
         uint value = 0;

         _address.transfer(value);
     }

}