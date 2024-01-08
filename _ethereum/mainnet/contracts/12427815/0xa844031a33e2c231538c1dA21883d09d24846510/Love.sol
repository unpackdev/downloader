// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Ownable.sol";
import "./ERC20.sol";

contract Love is ERC20, Ownable {
	constructor() ERC20("love.io", "LOVE") {
		address _owner = 0x4cbB78f5725FFba9A3Dae80F01d308403C4fe2c7;
		_mint(_owner, 1000000000 * (10**uint256(18)));
		transferOwnership(_owner);
	}
}
