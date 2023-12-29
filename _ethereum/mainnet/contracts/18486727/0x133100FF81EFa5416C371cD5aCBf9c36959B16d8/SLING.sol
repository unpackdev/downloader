// Telegram: https://t.me/bet_slinger
// Twitter:  https://x.com/bet_slinger

// $$$$$$$\  $$$$$$$$\ $$$$$$$$\   $$$$$$\  $$\       $$$$$$\ $$\   $$\  $$$$$$\  $$$$$$$$\ $$$$$$$\
// $$  __$$\ $$  _____|\__$$  __| $$  __$$\ $$ |      \_$$  _|$$$\  $$ |$$  __$$\ $$  _____|$$  __$$\
// $$ |  $$ |$$ |         $$ |    $$ /  \__|$$ |        $$ |  $$$$\ $$ |$$ /  \__|$$ |      $$ |  $$ |
// $$$$$$$\ |$$$$$\       $$ |    \$$$$$$\  $$ |        $$ |  $$ $$\$$ |$$ |$$$$\ $$$$$\    $$$$$$$  |
// $$  __$$\ $$  __|      $$ |     \____$$\ $$ |        $$ |  $$ \$$$$ |$$ |\_$$ |$$  __|   $$  __$$<
// $$ |  $$ |$$ |         $$ |    $$\   $$ |$$ |        $$ |  $$ |\$$$ |$$ |  $$ |$$ |      $$ |  $$ |
// $$$$$$$  |$$$$$$$$\    $$ |    \$$$$$$  |$$$$$$$$\ $$$$$$\ $$ | \$$ |\$$$$$$  |$$$$$$$$\ $$ |  $$ |
// \_______/ \________|   \__|     \______/ \________|\______|\__|  \__| \______/ \________|\__|  \__|

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract SLING is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public rewardsWallet;
    address public marketingWallet;
    address public operationsWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyRewardsFee;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyOperationsFee;

    uint256 public sellTotalFees;
    uint256 public sellRewardsFee;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellOperationsFee;

    uint256 public tokensForRewards;
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForOperations;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(
        address _router
    ) ERC20("Bet Slinger", "SLING") Ownable(msg.sender) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyRewardsFee = 1;
        uint256 _buyMarketingFee = 4;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyOperationsFee = 10;

        uint256 _sellRewardsFee = 1;
        uint256 _sellMarketingFee = 4;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellOperationsFee = 10;

        uint256 totalSupply = 1000000 * 1e18;

        maxTransactionAmount = (totalSupply * 15) / 1000; // 1.5% from total supply maxTransactionAmountTxn
        maxWallet = (totalSupply * 15) / 1000; // 1.5% from total supply maxWallet
        swapTokensAtAmount = (totalSupply * 5) / 1000; // 0.5% swap wallet

        buyRewardsFee = _buyRewardsFee;
        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyOperationsFee = _buyOperationsFee;
        buyTotalFees =
            buyRewardsFee +
            buyMarketingFee +
            buyLiquidityFee +
            buyOperationsFee;

        sellRewardsFee = _sellRewardsFee;
        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellOperationsFee = _sellOperationsFee;
        sellTotalFees =
            sellRewardsFee +
            sellMarketingFee +
            sellLiquidityFee +
            sellOperationsFee;

        rewardsWallet = address(0x90Bb4e4d3DF2103BBEDBd330dD366C70927ACAa9); // set as rewards wallet
        marketingWallet = address(0x5275e0c8038BE2B1B982e15d405f6BCB902a789B); // set as marketing wallet
        operationsWallet = address(0x7cAeA506E45a63dc367a28643757279E14b865B1); // set as operations wallet

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

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 2) / 100,
            "Swap amount cannot be higher than 2% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.5%"
        );
        maxTransactionAmount = newNum * (10 ** 18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10 ** 18);
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _rewardsFee,
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _operationsFee
    ) external onlyOwner {
        require(
            (_rewardsFee + _marketingFee + _liquidityFee + _operationsFee) <=
                30,
            "Max BuyFee 30%"
        );
        buyRewardsFee = _rewardsFee;
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyOperationsFee = _operationsFee;
        buyTotalFees =
            buyRewardsFee +
            buyMarketingFee +
            buyLiquidityFee +
            buyOperationsFee;
    }

    function updateSellFees(
        uint256 _rewardsFee,
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _operationsFee
    ) external onlyOwner {
        require(
            (_rewardsFee + _marketingFee + _liquidityFee + _operationsFee) <=
                30,
            "Max SellFee 30%"
        );
        sellRewardsFee = _rewardsFee;
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellOperationsFee = _operationsFee;
        sellTotalFees =
            sellRewardsFee +
            sellMarketingFee +
            sellLiquidityFee +
            sellOperationsFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
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

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
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
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
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

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
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
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForRewards += (fees * sellRewardsFee) / sellTotalFees;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForOperations +=
                    (fees * sellOperationsFee) /
                    sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForRewards += (fees * buyRewardsFee) / buyTotalFees;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operationsWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForRewards +
            tokensForLiquidity +
            tokensForMarketing +
            tokensForOperations;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForRewards = ethBalance.mul(tokensForRewards).div(
            totalTokensToSwap
        );
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );
        uint256 ethForOperations = ethBalance.mul(tokensForOperations).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance -
            ethForRewards -
            ethForMarketing -
            ethForOperations;

        tokensForLiquidity = 0;
        tokensForRewards = 0;
        tokensForMarketing = 0;
        tokensForOperations = 0;

        (success, ) = address(operationsWallet).call{value: ethForOperations}(
            ""
        );
        (success, ) = address(marketingWallet).call{value: ethForMarketing}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(rewardsWallet).call{value: address(this).balance}(
            ""
        );
    }
}
