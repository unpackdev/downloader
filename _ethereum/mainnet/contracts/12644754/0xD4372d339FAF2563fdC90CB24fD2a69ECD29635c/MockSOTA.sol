//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract MockSOTA is ERC20 {
	constructor() public ERC20('SOTA', 'SOTA') {
		_setupDecimals(18);
		_mint(msg.sender, 1000000 * (10**uint256(18)));
	}

	function mint(uint256 amount) external {
		_mint(msg.sender, amount);
	}
}
