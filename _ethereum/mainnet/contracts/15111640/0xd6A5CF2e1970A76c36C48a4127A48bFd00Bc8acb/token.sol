//SPDX-License-Identifier: MIT
/*
If you want to be a true citizen then, be.
 _______  ___   _______    _______  ___   _______  ___   _______  _______  __    _
|  _    ||   | |       |  |       ||   | |       ||   | |       ||       ||  |  | |
| |_|   ||   | |    ___|  |       ||   | |_     _||   | |____   ||    ___||   |_| |
|       ||   | |   | __   |       ||   |   |   |  |   |  ____|  ||   |___ |       |
|  _   | |   | |   ||  |  |      _||   |   |   |  |   | | ______||    ___||  _    |
| |_|   ||   | |   |_| |  |     |_ |   |   |   |  |   | | |_____ |   |___ | | |   |
|_______||___| |_______|  |_______||___|   |___|  |___| |_______||_______||_|  |__|

*/

pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";


contract TrueCitizen is ERC20, Ownable {

    string constant _name = "True Citizen";
    string constant _symbol = "TCTZ";
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 _totalSupply = 777000000 * (10 ** decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    mapping(address => bool) isFeeExempt;
    uint256 totalFee = 3;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public router;
    address public pair;

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || balanceOf(recipient) + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        uint256 taxed = shouldTakeFee(sender) ? getFeeAmount(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function getFeeAmount(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = amount * totalFee / 100;
        return feeAmount;
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    constructor () ERC20(_name, _symbol) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        isFeeExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }


}