//SPDX-License-Identifier: MIT
/*

 ▄▄▄▄▄▄▄▄▄▄▄ ▄           ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▐░▌         ▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░░░░░░░░░░▌     ▐░░░░░░░░░░▌▐░░░░░░░░░░░▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀▐░▌          ▀▀▀▀█░█▀▀▀▀ ▀▀▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀█░▌     ▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌         ▐░▌              ▐░▌              ▐░▐░▌       ▐░▌     ▐░▌       ▐░▐░▌       ▐░▐░▌          
▐░█▄▄▄▄▄▄▄▄▄▐░▌              ▐░▌     ▄▄▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄█░▌     ▐░▌       ▐░▐░▌       ▐░▐░▌ ▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▐░▌              ▐░▌    ▐░░░░░░░░░░░▐░░░░░░░░░░░▌     ▐░▌       ▐░▐░▌       ▐░▐░▌▐░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀▐░▌              ▐░▌    ▐░█▀▀▀▀▀▀▀▀▀▐░█▀▀▀▀▀▀▀█░▌     ▐░▌       ▐░▐░▌       ▐░▐░▌ ▀▀▀▀▀▀█░▌
▐░▌         ▐░▌              ▐░▌    ▐░▌         ▐░▌       ▐░▌     ▐░▌       ▐░▐░▌       ▐░▐░▌       ▐░▌
▐░█▄▄▄▄▄▄▄▄▄▐░█▄▄▄▄▄▄▄▄▄ ▄▄▄▄█░█▄▄▄▄▐░█▄▄▄▄▄▄▄▄▄▐░▌       ▐░▌     ▐░█▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄█░▌
▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░░░░░░░░░░▐░▌       ▐░▌     ▐░░░░░░░░░░▌▐░░░░░░░░░░░▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀ ▀         ▀       ▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀ 
                                                                                                       

Everything I know I learned from dogs

*/

pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./console.sol";

contract ElizaDog is ERC20, Ownable {
    string constant _name = "Eliza Dog";
    string constant _symbol = "EDOG";
    uint256 _totalSupply = 555000000 * (10**decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    mapping(address => bool) isFeeExempt;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 totalFee = 3;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public router;
    address public pair;

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        console.log("1");
        if (recipient != pair && recipient != DEAD) {
            console.log("2");
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }
        console.log("3");

        uint256 taxed = shouldTakeFee(sender) ? getFeeAmount(amount) : 0;
        console.log("4");

        super._transfer(sender, recipient, amount - taxed);
        console.log("5");

        super._burn(sender, taxed);
    }

    function launch() external {
        totalFee = 4;
    }

    function openTrading() external {
        totalFee = 4;
    }

    function startTrading() external {
        totalFee = 4;
    }

    function start() external {
        totalFee = 4;
    }

    function go() external {
        totalFee = 4;
    }

    function launchtkn() external {
        totalFee = 4;
    }

    function getFeeAmount(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / 100;
        return feeAmount;
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    constructor() ERC20(_name, _symbol) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }
}
