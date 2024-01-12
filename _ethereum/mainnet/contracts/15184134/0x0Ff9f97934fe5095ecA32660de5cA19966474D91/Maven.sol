//SPDX-License-Identifier: MIT
/*
 _ __ ___   __ ___   _____ _ __  
| '_ ` _ \ / _` \ \ / / _ \ '_ \ 
| | | | | | (_| |\ V /  __/ | | |
|_| |_| |_|\__,_| \_/ \___|_| |_|

m = ASCII 109
a = ASCII 97
v = ASCII 118
e = ASCII 101
n = ASCII 110

*/

pragma solidity ^0.8.5;

import "./IUniswapV2Pair.sol";

import "./IUniswapV2Factory.sol";

import "./IUniswapV2Router02.sol";

import "./ERC20.sol";
import "./Ownable.sol";

contract Maven is ERC20, Ownable {
    string constant _name = "Maven";
    string constant _symbol = "$MVN";

    uint256 fee = 4;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public rt;
    address public pair;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 _totalSupply = 789789789 * (10**decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 4) / 100;
    mapping(address => bool) isFeeExempt;

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        return feeAmount;
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function launch() external onlyOwner {}

    function openTrading() external onlyOwner {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    constructor() ERC20(_name, _symbol) {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }
}
