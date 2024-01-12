//SPDX-License-Identifier: MIT
/*
  .-.    __
 |   |  /\ \
 |   |  \_\/      __        .-.
 |___|        __ /\ \      /:::\
 |:::|       / /\\_\/     /::::/
 |:::|       \/_/        / `-:/
 ':::'__   _____ _____  /    /
     / /\ /     |:::::\ \   /
     \/_/ \     |:::::/  `"`
        __ `"""""""""`
       /\ \
       \_\/

*/
pragma solidity ^0.8.5;

import "./IUniswapV2Pair.sol";

import "./IUniswapV2Factory.sol";

import "./ERC20.sol";
import "./Ownable.sol";

import "./IUniswapV2Router02.sol";

contract Influenza is ERC20, Ownable {
    string constant _name = "Influenza";
    string constant _symbol = "$INFZ";

    uint256 fee = 2;

    function setLimit(uint256 amount) external onlyOwner {
        _maxW = (_totalSupply * amount) / 100;
    }

    function openTrading() external onlyOwner {
        tradingActive = true;
    }

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public rt;
    address public pair;

    bool private tradingActive;

    uint256 _totalSupply = 7000000000 * (10**decimals());
    uint256 public _maxW = (_totalSupply * 4) / 100;
    mapping(address => bool) isFeeExempt;

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!tradingActive) {
            require(
                isFeeExempt[sender] || isFeeExempt[recipient],
                "Trading is not active."
            );
        }
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxW,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    constructor() ERC20(_name, _symbol) {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0xdead)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    receive() external payable {}

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        return feeAmount;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
}
