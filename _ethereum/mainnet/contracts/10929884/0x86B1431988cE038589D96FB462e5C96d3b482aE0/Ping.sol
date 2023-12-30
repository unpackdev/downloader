pragma solidity ^0.4.0;



contract ReserveRetriever {
    uint112 reserve0;
    uint112 reserve1;
    uint blockTimestampLast;
    
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
}

contract Ping is ReserveRetriever {

    int8 ZZZinLP;
	ReserveRetriever ZZZETH;

	/*********
 	 Step 2: Deploy Ping, giving it the address of Pong.
 	 *********/
    constructor (ReserveRetriever _ZZZETHAddress) 
    {
        ZZZinLP = -1;							
        ZZZETH = _ZZZETHAddress;
    }

	/*********
     Step 3: Transactionally retrieve pongval from Pong. 
     *********/

	function getZZZinPool() 
	{
		(reserve0, reserve1, blockTimestampLast) = ZZZETH.getReserves();
	}
	
	/*********
     Step 5: Get pongval (which was previously retrieved from Pong via transaction)
     *********/
     
    function getPongvalConstant() constant returns (uint112)
    {
    	return reserve0;
    }
	
  
// -----------------------------------------------------------------------------------------------------------------	
	
	/*********
     Functions to get and set pongAddress just in case
     *********/
    
    function setZZZETHAddress(ReserveRetriever _ZZZETHAddress)
	{
		ZZZETH = _ZZZETHAddress;
	}
	
	function getPongAddress() constant returns (address)
	{
		return ZZZETH;
	}
 
}