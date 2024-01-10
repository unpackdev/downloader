/**
 * Submitted for verification at Etherscan.io on 2022-03-24
 */

//         _/_/                  _/                              _/          _/    _/_/_/        _/_/      _/_/
//      _/    _/      _/_/_/  _/_/_/_/    _/_/_/  _/  _/_/      _/          _/  _/            _/    _/  _/    _/
//     _/  _/_/    _/    _/    _/      _/    _/  _/_/          _/    _/    _/  _/                _/        _/
//    _/    _/    _/    _/    _/      _/    _/  _/              _/  _/  _/    _/              _/        _/
//     _/_/  _/    _/_/_/      _/_/    _/_/_/  _/                _/  _/        _/_/_/      _/_/_/_/  _/_/_/_/

/*
 * Website
 * http://qatarwc.xyz
 *
 * Telegram
 * https://t.me/fifaqatarwc22
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract QaTarWC is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public buyLiquidityFee = 2;
    uint256 public sellLiquidityFee = 3;
    uint256 public buyTxFee = 8;
    uint256 public sellTxFee = 10;
    uint256 public tokensForLiquidity;
    uint256 public tokensForTax;

    uint256 public _tTotal = 10**18; // 1 billion according to 9 decimals
    uint256 public swapAtAmount;
    uint256 public maxTxLimit;
    uint256 public maxWalletLimit;

    address public dev;
    address public immutable deployer;
    address public uniswapV2Pair;

    uint256 private launchBlock;
    bool private isSwapping;
    bool public isLaunched;

    // exclude from fees
    mapping(address => bool) public isExcludedFromFees;

    // exclude from max transaction amount
    mapping(address => bool) public isExcludedFromTxLimit;

    // exclude from max wallet limit
    mapping(address => bool) public isExcludedFromWalletLimit;

    // if the account is blacklisted from trading
    mapping(address => bool) public isBlacklisted;

    constructor(address _dev) ERC20("QaTarWC", "QWC") {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        // exclude from fees, wallet limit and transaction limit
        excludeFromAllLimits(owner(), true);
        excludeFromAllLimits(address(this), true);
        excludeFromWalletLimit(uniswapV2Pair, true);
        excludeFromAllLimits(0x000000000000000000000000000000000000dEaD, true);

        dev = _dev;
        deployer = _msgSender();

        swapAtAmount = _tTotal.mul(10).div(10000); // 0.10% of total supply
        maxTxLimit = _tTotal.mul(80).div(10000); // 0.80% of total supply
        maxWalletLimit = _tTotal.mul(160).div(10000); // 1.60% of total supply

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _tTotal);
    }

    function decimals() public pure override(ERC20) returns (uint8) {
        return 9;
    }

    function excludeFromFees(address account, bool value) public onlyOwner {
        require(
            isExcludedFromFees[account] != value,
            "Fees: Already set to this value"
        );
        isExcludedFromFees[account] = value;
    }

    function excludeFromTxLimit(address account, bool value) public onlyOwner {
        require(
            isExcludedFromTxLimit[account] != value,
            "TxLimit: Already set to this value"
        );
        isExcludedFromTxLimit[account] = value;
    }

    function excludeFromWalletLimit(address account, bool value)
        public
        onlyOwner
    {
        require(
            isExcludedFromWalletLimit[account] != value,
            "WalletLimit: Already set to this value"
        );
        isExcludedFromWalletLimit[account] = value;
    }

    function excludeFromAllLimits(address account, bool value)
        public
        onlyOwner
    {
        excludeFromFees(account, value);
        excludeFromTxLimit(account, value);
        excludeFromWalletLimit(account, value);
    }

    function setBuyFee(uint256 liquidityFee, uint256 txFee) external onlyOwner {
        buyLiquidityFee = liquidityFee;
        buyTxFee = txFee;
    }

    function setSellFee(uint256 liquidityFee, uint256 txFee)
        external
        onlyOwner
    {
        sellLiquidityFee = liquidityFee;
        sellTxFee = txFee;
    }

    function setMaxTxLimit(uint256 newLimit) external onlyOwner {
        maxTxLimit = newLimit * (10**9);
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner {
        maxWalletLimit = newLimit * (10**9);
    }

    function setSwapAtAmount(uint256 amountToSwap) external onlyOwner {
        swapAtAmount = amountToSwap * (10**9);
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        dev = newWallet;
    }

    function addBlacklist(address account) external onlyOwner {
        require(!isBlacklisted[account], "Blacklist: Already blacklisted");
        require(account != uniswapV2Pair, "Cannot blacklist pair");
        _setBlacklist(account, true);
    }

    function removeBlacklist(address account) external onlyOwner {
        require(isBlacklisted[account], "Blacklist: Not blacklisted");
        _setBlacklist(account, false);
    }

    function launchNow() external onlyOwner {
        require(!isLaunched, "Contract is already launched");
        isLaunched = true;
        launchBlock = block.number;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(
            amount <= maxTxLimit ||
                isExcludedFromTxLimit[from] ||
                isExcludedFromTxLimit[to],
            "Tx Amount too large"
        );
        require(
            balanceOf(to).add(amount) <= maxWalletLimit ||
                isExcludedFromWalletLimit[to],
            "Transfer will exceed wallet limit"
        );
        require(
            isLaunched || isExcludedFromFees[from] || isExcludedFromFees[to],
            "Waiting to go live"
        );
        require(!isBlacklisted[from], "Sender is blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 totalTokensForFee = tokensForLiquidity + tokensForTax;
        bool canSwap = totalTokensForFee >= swapAtAmount;

        if (from != uniswapV2Pair && canSwap && !isSwapping) {
            isSwapping = true;
            swapBack(totalTokensForFee);
            isSwapping = false;
        } else if (
            from == uniswapV2Pair &&
            to != uniswapV2Pair &&
            block.number < launchBlock + 2 &&
            !isExcludedFromFees[to]
        ) {
            _setBlacklist(to, true);
        }

        bool takeFee = !isSwapping;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;
            // on sell
            if (to == uniswapV2Pair) {
                uint256 sellTotalFees = sellLiquidityFee.add(sellTxFee);
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = tokensForLiquidity.add(
                    fees.mul(sellLiquidityFee).div(sellTotalFees)
                );
                tokensForTax = tokensForTax.add(
                    fees.mul(sellTxFee).div(sellTotalFees)
                );
            }
            // on buy & wallet transfers
            else {
                uint256 buyTotalFees = buyLiquidityFee.add(buyTxFee);
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = tokensForLiquidity.add(
                    fees.mul(buyLiquidityFee).div(buyTotalFees)
                );
                tokensForTax = tokensForTax.add(
                    fees.mul(buyTxFee).div(buyTotalFees)
                );
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount = amount.sub(fees);
            }
        }

        super._transfer(from, to, amount);
    }

    function swapBack(uint256 totalTokensForFee) private {
        uint256 toSwap = swapAtAmount;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = toSwap
            .mul(tokensForLiquidity)
            .div(totalTokensForFee)
            .div(2);
        uint256 taxTokens = toSwap.sub(liquidityTokens).sub(liquidityTokens);
        uint256 amountToSwapForETH = toSwap.sub(liquidityTokens);

        _swapTokensForETH(amountToSwapForETH);

        uint256 ethBalance = address(this).balance;
        uint256 ethForTax = ethBalance.mul(taxTokens).div(amountToSwapForETH);
        uint256 ethForLiquidity = ethBalance.sub(ethForTax);

        tokensForLiquidity = tokensForLiquidity.sub(liquidityTokens.mul(2));
        tokensForTax = tokensForTax.sub(toSwap.sub(liquidityTokens.mul(2)));

        payable(address(dev)).transfer(ethForTax);
        _addLiquidity(liquidityTokens, ethForLiquidity);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            deployer,
            block.timestamp
        );
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _setBlacklist(address account, bool value) internal {
        isBlacklisted[account] = value;
    }

    receive() external payable {}
}
