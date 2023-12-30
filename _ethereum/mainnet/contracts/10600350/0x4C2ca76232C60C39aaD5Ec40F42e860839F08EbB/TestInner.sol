pragma solidity ^0.5.1;

contract TestInner {

    function sendInner(address payable account) public payable {
        account.transfer(msg.value);
    }
    
}