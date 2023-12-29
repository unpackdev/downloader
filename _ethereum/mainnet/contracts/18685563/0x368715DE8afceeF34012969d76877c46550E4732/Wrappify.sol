// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// It's that time of the year again! Connect your wallet and share your 2023 On-Chain Wrapped, exclusively on #Wrappify.
// Website: https://wrappify.app
// Telegram: https://t.me/wrappify
// Twitter: https://twitter.com/Wrappify_

import "./ERC20.sol";
import "./Safemath.sol";
import "./Uniswap.sol";
import "./IUniswapFactory.sol";

contract Wrappify is ERC20, Ownable {
    event SwapBackSuccess(
        uint256 tokenAmount,
        uint256 ethAmountReceived,
        bool success
    );
    bool private swapping;
    address public marketingWallet;

    address public devWallet;

    using SafeMath for uint256;

    uint256 _totalSupply = 1_000_000 * 1e18;
    uint256 public maxTransactionAmount = (_totalSupply * 10) / 1000; // 1% from total supply maxTransactionAmountTxn;
    uint256 public swapTokensAtAmount = (_totalSupply * 50) / 10000; // 0.5% swap tokens at this amount
    uint256 public maxWallet = (_totalSupply * 10) / 1000; // 1% from total supply maxWallet

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyFees = 5;
    uint256 public sellFees = 5;

    uint256 public marketingAmount = 30; //
    uint256 public devAmount = 70; //

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    constructor(
        address _realOwner,
        address _marketing,
        address _dev,
        address _factoryAddress,
        address _routerAddress
    ) ERC20("Wrappify", "WRP") {
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
        IUniswapFactory factory = IUniswapFactory(_factoryAddress);
        address pairAddress = factory.createPair(address(this), uniswapV2Router.WETH());
        marketingWallet = _marketing;
        devWallet = _dev;
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(_realOwner, true);
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(devWallet, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(_realOwner, true);
        automatedMarketMakerPairs[pairAddress] = true;
        _mint(owner(), _totalSupply * 85 / 100);
        _mint(_realOwner, _totalSupply * 15 / 100);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable (sets sell fees to 5%)
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        sellFees = 5;
        buyFees = 5;
        return true;
    }

    function excludeFromMaxTransaction(
        address addressToExclude,
        bool isExcluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[addressToExclude] = isExcluded;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function addLiquidity() external payable onlyOwner {
        // approve token transfer to cover all possible scenarios
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        _approve(address(this), address(uniswapV2Router), totalSupply());
        // add the liquidity
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this), //token address
            totalSupply(), // liquidity amount
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), // LP tokens are sent to the owner
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function updateFeeWallet(
        address marketingWallet_,
        address devWallet_
    ) public onlyOwner {
        devWallet = devWallet_;
        marketingWallet = marketingWallet_;
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
        require(amount > 0, "Transfer amount must be greater than zero");
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not enabled yet."
                    );
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        if (
            swapEnabled && //if this is true
            !swapping && //if this is false
            !automatedMarketMakerPairs[from] && //if this is false
            !_isExcludedFromFees[from] && //if this is false
            !_isExcludedFromFees[to] //if this is false
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
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellFees > 0) {
                fees = amount.mul(sellFees).div(100);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyFees > 0) {
                fees = amount.mul(buyFees).div(100);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
        if (contractBalance == 0) {
            return;
        }
        if (contractBalance >= swapTokensAtAmount) {
            uint256 amountToSwapForETH = swapTokensAtAmount;
            swapTokensForEth(amountToSwapForETH);
            uint256 amountEthToSend = address(this).balance;
            uint256 amountToMarketing = amountEthToSend
                .mul(marketingAmount)
                .div(100);
            uint256 amountToDev = amountEthToSend.sub(amountToMarketing);
            (success, ) = address(marketingWallet).call{
                value: amountToMarketing
            }("");
            (success, ) = address(devWallet).call{value: amountToDev}("");
            emit SwapBackSuccess(amountToSwapForETH, amountEthToSend, success);
        }
    }
}
