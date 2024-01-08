pragma solidity ^0.8.4;


contract ZenChipGaming

{
 

   function Gaming() public view returns(
	
	string memory , 
	address GamingInitiator, 
	uint256 time)
    
	{
        
		return ("ZenChip Gaming Smart Contracts Taking the Gaming Industry to the Blockchain for creating historical data and just plain old fun.", msg.sender, block.timestamp);
    
	}
    

}