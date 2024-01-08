pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract threeToken is ERC20Standard {
	constructor() public {
		_totalSupply = 600000;
		name = "Triple Ex";
		decimals = 0;
		symbol = "3-Ex";
		version = "1.0";
		balances[owner] = _totalSupply;
	}
}
