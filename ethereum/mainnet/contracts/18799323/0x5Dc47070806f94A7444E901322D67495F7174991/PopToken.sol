// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "ERC20.sol";
import "Ownable.sol";

contract PopToken is ERC20, Ownable {
    bool public limited;
    uint256 private startTime;
    uint256 private lockDuration = 1 hours;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;

    mapping(address => bool) public poolLists;
    mapping(address => bool) public blacklists;

    constructor(uint256 initialSupply) ERC20("PopGame", "PopGame") {
        _mint(msg.sender, initialSupply);
    }

    function setRule(
        uint256 _maxHoldingAmount,
        address _uniswapV2Pair
    ) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;

        if (startTime == 0) {
            startTime = block.timestamp;
        }
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        bool isInLimitedTime = block.timestamp < (startTime + lockDuration);

        if (isInLimitedTime && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }
}
