pragma solidity >= 0.5.0 < 0.6.0;

contract SavingAccountParameters {
    string public ratesURL;
	string public tokenNames;
    address[] public tokenAddresses;

    constructor() public payable{
      tokenNames = "ETH,USDT,PROS";
	  tokenAddresses = new address[](3);
	  tokenAddresses[0] = 0x000000000000000000000000000000000000000E; 
      tokenAddresses[1] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 
      tokenAddresses[2] = 0x306Dd7CD66d964f598B4D2ec92b5a9B275D7fEb3;//usdt //change address for test
	}

	function getTokenAddresses() public view returns(address[] memory){
        return tokenAddresses;
    }
}