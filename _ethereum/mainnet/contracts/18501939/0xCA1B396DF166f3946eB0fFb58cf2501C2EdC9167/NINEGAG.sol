// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

/**
 * @title NINEGAG
 * @tg https://t.me/nineGAGv3token
 */

import "./ERC20.sol";
import "./Ownable.sol";

contract NINEGAG is Ownable, ERC20("9GAG", "9GAG") {
    bool public limited;
    uint256 public maxHoldingAmount;
    address public uniswapPool;

    constructor() {
        uint256 TOTAL_SUPPLY = 69_000_000 ether;
        maxHoldingAmount = (TOTAL_SUPPLY * 25) / 10_000;
        limited = true;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function setPool(address _uniswapPool) external onlyOwner {
        uniswapPool = _uniswapPool;
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (uniswapPool == address(0)) {
            require(tx.origin == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapPool) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "MAX WALLET AMOUNT EXCEEDED");
        }
    }
}
