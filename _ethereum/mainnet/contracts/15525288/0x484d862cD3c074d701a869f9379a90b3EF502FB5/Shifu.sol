// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**

🆂🅷🅸🅵🆄 🆃🅷🅴 🅼🅰🆂🆃🅴🆁

https://shifuthemaster.com
https://twitter.com/shifuthemaster1
https://shifuthemaster.medium.com


Shifu awaits his new apprentices.

Through the coming days you will learn the craft and when ready - venture on a journey to defeat the darkness.

The best warriors will be invited to fight alongside Shifu.

Only the patient and dedicated students will be rewarded!

 */

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/* solhint-disable not-rely-on-time */
/* solhint-disable max-states-count */
/* solhint-disable reason-string */
contract Shifu is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    // solhint-disable-next-line var-name-mixedcase
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    bool private swapping;

    address public devWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyDevFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellDevFee;
    uint256 public sellLiquidityFee;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event DevWalletUpdated(address indexed newWallet, address indexed oldWallet);

    constructor() ERC20("Shifu The Master", "SHIFU") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 _buyDevFee = 3;
        uint256 _buyLiquidityFee = 2;

        uint256 _sellDevFee = 3;
        uint256 _sellLiquidityFee = 2;

        uint256 totalSupply = 100_000_000_000 * 1e18;

        maxTransactionAmount = totalSupply / 100; // 1% from total supply maxTransactionAmountTxn
        maxWallet = (totalSupply * 2) / 100; // 2% from total supply maxWallet
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap threshold

        buyDevFee = _buyDevFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyDevFee + buyLiquidityFee;

        sellDevFee = _sellDevFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellDevFee + sellLiquidityFee;

        devWallet = address(0xDca2dBfD85A04925c8D380A5881e07f130372335); // set as dev wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
        require(newAmount >= totalSupply() / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }

    // newNum in tokens, not wei
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum * 1e18 >= totalSupply() / 1000, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * 1e18;
    }

    // newNum in tokens, not wei
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum * 1e18 >= (totalSupply() * 5) / 1000, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * 1e18;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        buyDevFee = _devFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyDevFee + buyLiquidityFee;
        require(buyTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function updateSellFees(uint256 _devFee, uint256 _liquidityFee) external onlyOwner {
        sellDevFee = _devFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellDevFee + sellLiquidityFee;
        require(sellTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateDevWallet(address newDevWallet) external onlyOwner {
        emit DevWalletUpdated(newDevWallet, devWallet);
        devWallet = newDevWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
                if (!tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                //when buy
                if (from == uniswapV2Pair && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            to == uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 tokensForLiquidity = 0;
        uint256 tokensForDev = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (to == uniswapV2Pair && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDev = (fees * sellDevFee) / sellTotalFees;
            }
            // on buy
            else if (from == uniswapV2Pair && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDev = (fees * buyDevFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            if (tokensForLiquidity > 0) {
                super._transfer(address(this), uniswapV2Pair, tokensForLiquidity);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForUSDC(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDC
            path,
            devWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForUSDC(contractBalance);
    }
}
