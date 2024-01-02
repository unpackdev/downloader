// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MatmoToken is ERC20, ERC20Burnable, Ownable {
	address private constant _router =
		0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

	address private _launcher;
	bool public tradingEnabled;

	mapping(address => bool) private _pairs;

	event TradingEnabled();
	event LauncherUpdated();
	event PairsUpdated();

	constructor(uint256 maxSupply) ERC20("Matmo", "MAMO") {
		_approve(_msgSender(), _router, type(uint256).max);
		_mint(_msgSender(), maxSupply * 10 ** 18);
	}

	function enableTrading() external onlyOwner {
		require(!tradingEnabled, "MAMO: trading already enabled");
		tradingEnabled = true;
		emit TradingEnabled();
	}

	function setLauncher(address launcher) external onlyOwner {
		require(!tradingEnabled, "MAMO: trading already enabled");
		_approve(launcher, _router, type(uint256).max);
		_launcher = launcher;
		emit LauncherUpdated();
	}

	function setPairs(
		address[] calldata pairs,
		bool[] calldata status
	) external onlyOwner {
		require(!tradingEnabled, "MAMO: trading already enabled");
		require(pairs.length == status.length, "MAMO: invalid parameters");
		for (uint256 i = 0; i < pairs.length; i++) {
			_pairs[pairs[i]] = status[i];
		}
		emit PairsUpdated();
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		require(from != address(0), "MAMO: transfer from the zero address");
		require(to != address(0), "MAMO: transfer to the zero address");

		if (!tradingEnabled) {
			if (_pairs[from] || _pairs[to]) {
				_pairs[from]
					? require(
						to == owner() || to == _launcher,
						"MAMO: trading disabled"
					)
					: require(
						from == owner() || from == _launcher,
						"MAMO: trading disabled"
					);
			}
		}

		super._transfer(from, to, amount);
	}
}
