// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract MemeTest is ERC20, Ownable {
    address public initialOwner = 0x89cC04a4E31895b088641e973247E6e36FF432cf;
    address public marketingWallet = 0xa61935a013552cBDB95b388E615c3c7A938b9B52;
    IUniswapV2Router02 public immutable dexRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable pairAddress;
    uint256 public tokenSupply = 100000 * 10 ** decimals();
    uint256 maxHold = (tokenSupply * 5) / 1000;
    uint256 maxTransfer = tokenSupply / 100;
    uint8 public buyTax = 0;
    uint8 public sellTax = 40;
    bool public launchCompleted = false;
    event BuyTaxChanged(uint8 indexed oldTax, uint8 indexed newTax);
    event SellTaxChanged(uint8 indexed oldTax, uint8 indexed newTax);

    constructor() ERC20("MemeTest", "MT01") Ownable(initialOwner) {
        pairAddress = address(
            IUniswapV2Factory(dexRouter.factory()).createPair(
                address(this),
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            )
        );
        _mint(initialOwner, tokenSupply);
    }

    function completeLaunch() external onlyOwner {
        launchCompleted = true;
        emit BuyTaxChanged(buyTax, 0);
        emit SellTaxChanged(sellTax, 0);
        buyTax = 0;
        sellTax = 0;
        renounceOwnership();
    }

    function adjustBuyTax(uint8 _taxPercentage) external onlyOwner {
        require(_taxPercentage <= 25, "Max buy tax percentage is 25%!");
        emit BuyTaxChanged(buyTax, _taxPercentage);
        buyTax = _taxPercentage;
    }

    function adjustSellTax(uint8 _taxPercentage) external onlyOwner {
        require(_taxPercentage <= 25, "Max sell tax percentage is 25%!");
        emit SellTaxChanged(sellTax, _taxPercentage);
        sellTax = _taxPercentage;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        // after launch or if no tax proceed as normal
        if (
            launchCompleted ||
            (buyTax == 0 && sellTax == 0) ||
            from == owner() ||
            to == owner() ||
            from == marketingWallet ||
            to == marketingWallet
        ) {
            super._update(from, to, value);
        } else if (!launchCompleted) {
            // collect marketing fee
            uint256 marketingFee = 0;
            // buying
            if (from == pairAddress) {
                require(
                    value <= maxTransfer,
                    "You are not allowed to buy more than maxTransfer!"
                );
                require(
                    value + balanceOf(to) <= maxHold,
                    "You are not allowed to hold more than maxHold!"
                );
                marketingFee = (value / 100) * buyTax;
            // selling
            } else if (to == pairAddress) {
                require(
                    value <= maxTransfer,
                    "You are not allowed to sell more than maxTransfer!"
                );
                marketingFee = (value / 100) * sellTax;
            }
            // block illegal transfers at launch
            else {
                require(
                    value <= maxTransfer,
                    "You are not allowed to transfer more than maxTransfer!"
                );
                require(
                    value + balanceOf(to) <= maxHold,
                    "You are not allowed to hold more than maxHold!"
                );
            }
            if (marketingFee > 0) {
                value -= marketingFee;
                super._update(from, marketingWallet, marketingFee);
            }
            super._update(from, to, value);
        }
    }
}
