
//SPDX-License-Identifier: Unlicensed
/**

The perfect implementation of ERC20. Reduced gas costs.

**/
pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract TrueERC20 is ERC20, Ownable {


    uint256 _totalSupply = 1000000 * (10 ** decimals());
    address DEAD = 0x000000000000000000000000000000000000dEaD;
   
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    mapping (address => bool) noLimit;
    uint256 totalFee = 5;
    IUniswapV2Router02 public router;
    address public pair;

    constructor () ERC20("True ERC20", "TERC20") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        noLimit[owner()] = true;
        noLimit[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }


    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 100;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(noLimit[recipient] || balanceOf(recipient) + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        uint256 taxed = !noLimit[sender] ? amount * totalFee / 100 : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }
}