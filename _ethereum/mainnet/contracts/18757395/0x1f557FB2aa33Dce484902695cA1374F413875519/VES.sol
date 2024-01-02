// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract VES is ERC20Burnable, Ownable {
    uint256 public constant TOTAL_SUPPLY = 500_000_000e18;
    uint256 public constant PRECISION = 1000;

    address public uniswapV2Pair;
    address public marketingWallet;

    uint256 public buyFee;
    uint256 public sellFee;

    mapping(address => bool) public excludedFromFees;

    constructor(
        address marketingWallet_
    ) ERC20("VESTATE", "VES") Ownable(msg.sender) {
        _mint(owner(), TOTAL_SUPPLY);
        marketingWallet = marketingWallet_;
    }

    function setMarketingWallet(address marketingWallet_) external onlyOwner {
        require(
            marketingWallet != address(0) &&
                marketingWallet_ != marketingWallet,
            "VES: Wrong Address"
        );
        marketingWallet = marketingWallet_;
    }

    function setBuyFee(uint256 buyFee_) external onlyOwner {
        require(buyFee_ <= 100, "VES: Wrong Buy Fee");
        buyFee = buyFee_;
    }

    function setSellFee(uint256 sellFee_) external onlyOwner {
        require(sellFee_ <= 100, "VES: Wrong Sell Fee");
        sellFee = sellFee_;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        excludedFromFees[account] = excluded;
    }

    function setUniswapV2Pair(address uniswapV2Pair_) external onlyOwner {
        uniswapV2Pair = uniswapV2Pair_;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            (sellFee == 0 && buyFee == 0) ||
            (excludedFromFees[from] || excludedFromFees[to])
        ) {
            super._update(from, to, amount);
            return;
        }
        if (uniswapV2Pair != address(0)) {
            if (from == uniswapV2Pair) {
                uint256 fee = calculateFee(amount, true);
                super._update(from, marketingWallet, fee);
                super._update(from, to, amount - fee);
                return;
            }
            if (to == uniswapV2Pair) {
                uint256 fee = calculateFee(amount, false);
                super._update(from, marketingWallet, fee);
                super._update(from, to, amount - fee);
                return;
            }
        }

        super._update(from, to, amount);
    }

    function calculateFee(
        uint amount,
        bool isBuying
    ) public view returns (uint256 fee) {
        if (isBuying) {
            fee = (amount * buyFee) / PRECISION;
        } else {
            fee = (amount * sellFee) / PRECISION;
        }
    }
}
