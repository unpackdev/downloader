
//SPDX-License-Identifier: MIT
/**
    The ark community coin. TG will be revealed after 10k liquidity pool to rekt all bots.
**/
pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract THEARK is ERC20, Ownable {

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 _totalSupply = 666666666 * (10 ** decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    string constant _name = "THE ARK";
    string constant _symbol = "ARK";
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    uint256 totalFee = 3;
    IUniswapV2Router02 public router;
    address public pair;

    constructor () ERC20(_name, _symbol) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        isFeeExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function getFeeAmount(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = amount * totalFee / 100;
        return feeAmount;
    }
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 100;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || balanceOf(recipient) + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        uint256 taxed = shouldTakeFee(sender) ? getFeeAmount(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }
}