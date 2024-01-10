// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

//███████ ████████  █████  ██████
//██         ██    ██   ██ ██   ██
//███████    ██    ███████ ██████
//     ██    ██    ██   ██ ██   ██
//███████    ██    ██   ██ ██   ██
contract STAR is Ownable, ERC20Permit {
	constructor() ERC20("STAR", "STAR") ERC20Permit("STAR") {
		tokenDistribution(); //this is run only once!
	}

	function mint(address to, uint256 amount) external onlyOwner {
		require(totalSupply() + amount <= 10000000000 ether, "over max supply");
		_mint(to, amount);
	}

	function tokenDistribution() internal {
		_mint(0x69a1F8853CE46cA85712Ca609D2Ff2D0763e8B27, 1000000000 ether);
	}
}
