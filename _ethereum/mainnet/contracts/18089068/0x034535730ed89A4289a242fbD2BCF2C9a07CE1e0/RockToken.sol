// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract RockToken is ERC20, Ownable {
    mapping(address=>bool) public bots;
    uint256 public maxHoldingAmount;
    address public uniswapPair;

    constructor() ERC20("Rock7.0", "ROCK7") {
      _mint(msg.sender, 75*10**(9+decimals()));
      _mint(address(this), 25*10**(9+decimals()));
    }

	function setBots(address[] memory _bots, bool _isBot) external onlyOwner() {
		for (uint256 i=0; i<_bots.length; i++) {
			bots[_bots[i]] = _isBot;
		}
	}

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!bots[from] && !bots[to], "Bot Forbid");

        if (maxHoldingAmount > 0 && from == uniswapPair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Exceed Max Holding");
        }
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function setConfig(address _uniswapPair, uint256 _maxHoldingAmount) external onlyOwner {
        uniswapPair = _uniswapPair;
        maxHoldingAmount = _maxHoldingAmount;
    }
}
