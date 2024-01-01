// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract Vivek is Ownable, ERC20 {
    uint8 public tradingStarted;
    // 69B
    uint256 public MAX_SUPPLY = 69000000000 * 10 ** 18;

    constructor() ERC20("Vivek", "VIVEK") {
        _mint(msg.sender, MAX_SUPPLY);
        tradingStarted = 0;
    }

    function setTradingStarted(uint8 _tradingStarted) external onlyOwner {
        tradingStarted = _tradingStarted;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (tradingStarted == 0) {
            require(from == owner() || to == owner(), "Trading is not started");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
