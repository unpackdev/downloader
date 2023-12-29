pragma solidity ^0.5.0;

contract sendMeTx{

    address payable public owner;
    uint256 lastTrackedBlock;
    
    
    // 3 days * 24 hours * 60 minutes * 60 seconds = 259.200 seconds
    // 259.200 seconds / 15 blocks/second = 17.280 blocks
    uint256 maxInterval = 3 * 24 * 60 * 60 / 15;
    
    //Actual Block + 24 hours * 60 minutes * 60 seconds * 7days / 15 block/sec = 40.320 blocks
    uint256 withdrawBlock = block.number + (24 * 60 * 60 * 7 / 15);
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier canWithdraw(){
        require(block.number > withdrawBlock);
        _;
    }
    
    

    constructor () public payable{
        
        owner = msg.sender;
        lastTrackedBlock = block.number;
 
    }
    
    
    function keepAlive() public payable{

        if(block.number - maxInterval <= lastTrackedBlock){
            lastTrackedBlock = block.number;
        } else {
            owner = msg.sender;
        }
        
    }
    
    
    function withdraw() onlyOwner canWithdraw public{
        owner.transfer(address(this).balance);
    }
    
}