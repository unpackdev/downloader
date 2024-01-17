pragma solidity ^0.8.0;

//FTX suck my live, I decided to give all my fucking eth away and leave the blockchain forever.
//Take it , fcfs.
//Read the smart contract yourself if you are an engineer

import "./Ownable.sol";

contract TryYourLuck is Ownable{
    
    uint num;
    bool start;

    constructor(address newOwner){
        _transferOwnership(newOwner);
    }
    
    function bet() public payable{
        require(start == true, "not start");
        require(msg.value >= 1 ether, "insufficient balance");
        if(random() < num/2){
            payable(msg.sender).transfer(address(this).balance);
        }
    }
    function random() private view returns(uint){
        //create random result
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % num;
    }
    function setNumAndStart(uint newNUm) public payable onlyOwner{
        //initial the number if the number not been set
        if(num == 0){
            num = newNUm;
        }
        start = true;
    }
    function stopGame() public payable onlyOwner {
        start = false;
        payable(msg.sender).transfer(address(this).balance);
    }
}