/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity ^0.7.0;

contract EarlyReturn {
   string public message;
   uint256 private test;
   uint256 private test2;
   uint256 private test3;

   constructor(string memory initMessage) {
    /* Set the message⁧ /*/ return ;
        message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}