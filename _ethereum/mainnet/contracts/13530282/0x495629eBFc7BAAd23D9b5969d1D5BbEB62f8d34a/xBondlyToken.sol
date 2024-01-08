// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./ERC20.sol";

import "./IxBondlyToken.sol";

contract xBondlyToken is IxBondlyToken, ERC20 {
	address public stakingContract;

	modifier onlyBondlyStaking() {
		require(stakingContract == _msgSender(), "xBondlyToken: permission denied");
		_;
	}

	constructor(address _stakingContract) ERC20("Staking Bondly", "xBondly") {
		stakingContract = _stakingContract;
	}

	function mint(address account, uint256 amount) public override onlyBondlyStaking {
		_mint(account, amount);
	}

	function burn(address account, uint256 amount) public override onlyBondlyStaking {
		_burn(account, amount);
	}
}
