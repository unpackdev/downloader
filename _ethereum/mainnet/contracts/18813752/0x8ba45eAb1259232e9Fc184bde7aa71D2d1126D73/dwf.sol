// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract DWF is ERC20, ERC20Burnable, Ownable {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapPair;
    address public liquidityProvider;
    bool public limited2;
    uint256 public maxPossessionAmount;
    mapping(address => bool) public blacklists;

    constructor(address initialOwner)
        ERC20("DWF Coin", "DWF")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }

    function setRule(bool _limited, address _uniswapPair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount, address _liquidityProvider, bool _limited2, uint256 _maxPossessionAmount) external onlyOwner {
        limited = _limited;
        uniswapPair = _uniswapPair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
        liquidityProvider = _liquidityProvider;
        limited2 = _limited2;
        maxPossessionAmount = _maxPossessionAmount;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        if (uniswapPair == address(0)) {
            require(from == owner() || to == owner(), "Trading has not started");
        }

        if (limited && from == uniswapPair && to != liquidityProvider) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid 1");
        }

        if (limited2 && block.timestamp < 1722466800) {
            
            if (from != liquidityProvider && from != uniswapPair){
                require(super.balanceOf(from) < maxPossessionAmount, "Forbid 2");
            }

            if (to != liquidityProvider && from != liquidityProvider && to != uniswapPair){
                require(super.balanceOf(to) + amount < maxPossessionAmount, "Forbid 3");
            }

        }

        super._update(from, to, amount);
    }

}