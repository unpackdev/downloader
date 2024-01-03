pragma solidity 0.7.1;

contract EscrowTheMovie{
    
    uint expectedAmount = 1340000000000000000;
    address public sender;
    address payable public receiver;
    bool released;
    
    constructor (){
        receiver = msg.sender;
    }
    
    function deposit(uint amount) public payable {
        require(msg.value == amount);
        sender = msg.sender;
    } 
    
    function release() public {
        require(msg.sender == sender);
        released = true;
    }
    
    function withdraw() public{
        require(msg.sender == receiver, "wrong caller");
        require(released, "not released");
        (bool success, ) = receiver.call{value: expectedAmount}("");
        require(success, "Unwrapping failed.");
    }
}