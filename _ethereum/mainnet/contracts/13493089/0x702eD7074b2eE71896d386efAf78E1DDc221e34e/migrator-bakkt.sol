// Be name khoda
// Bime abolfazl
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
interface IERC20 {
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Migrator is Ownable {
	/* ----- state variables --------*/
	address public fromCoin;
	uint256 public ratio;
	uint256 public scale = 1e18;
	uint256 public endBlock;

	/* ----- consturctor -------*/
	constructor (address _fromCoin, uint256 _ratio, uint256 _endBlock) {
		fromCoin = _fromCoin;
		ratio = _ratio;
		endBlock = _endBlock;
	}

	/* ----- modifiers -------*/
	modifier openMigrate {
		require(block.number <= endBlock, "Migration is closed");
		_;
	}

	/* ----- restricted functions -------*/
	function setFromCoin(address _fromCoin) external onlyOwner {
		fromCoin = _fromCoin;
	}

	function setEndBlock(uint256 _endBlock) external onlyOwner {
		endBlock = _endBlock;
	}

	function setRatio(uint256 _ratio) external onlyOwner {
		ratio = _ratio;
	}

	function withdraw(address to, uint256 amount, address token) external onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	/* ----- public functions -------*/
	function migrateFor(address user, uint256 amount, address toCoin) public openMigrate {
		IERC20(fromCoin).transferFrom(msg.sender, address(this), amount);
		IERC20(toCoin).mint(user, amount * ratio / scale);
		emit Migrate(user, amount * ratio / scale);
	}

	function migrate(uint256 amount, address toCoin) external {
		migrateFor(msg.sender, amount, toCoin);
	}

	/* ----- events -------*/
	event Migrate(address user, uint256 amount);
}
