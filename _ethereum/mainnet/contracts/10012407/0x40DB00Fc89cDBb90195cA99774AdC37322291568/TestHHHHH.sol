pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

	struct TokenMetadata {
		address token;
		string name;
		string symbol;
		uint8 decimals;
	}

contract TestHHHHH {
    TokenMetadata public a;
    
    //just trying to screw something up by having the immutable text here
    function createNewTokenMetadata() public {
        a.token = msg.sender;
        a.name = "Testing Me";
        a.symbol = "TSTME";
        a.decimals = 18;
    }
}