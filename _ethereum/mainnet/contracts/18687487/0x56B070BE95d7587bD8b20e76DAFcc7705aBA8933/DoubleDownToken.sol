/**
 * @notice Will Smith Double Down Token.
 * The ultimate token for you to be part of the game.
 *
 * Website: https://doubledowntoken.xyz/
 * X: https://x.com/DoubleDownDD
 * Telegram: https://t.me/doubledowndd
 **/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Batchable.sol";

contract DoubleDownToken is ERC20, Ownable, Batchable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    uint256 public constant TOTAL_SUPPLY = 10_000_000_000 ether;

    bool private swapping;

    address public marketingWallet;
    address public developmentWallet;
    address public liquidityWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 private buyTeamFee;
    uint256 private buyVaultFee;
    uint256 private buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 private sellTeamFee;
    uint256 private sellVaultFee;
    uint256 private sellLiquidityFee;

    uint256 private tokensForMarketing;
    uint256 private tokensForDevelopment;
    uint256 private tokensForLiquidity;
    uint256 private previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event developmentWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event liquidityWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(
        address _deployer,
        address _owner,
        address _teamWallet
    ) ERC20("Double Down Token", "DDT") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D //uniswap
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        maxTransactionAmount = (TOTAL_SUPPLY * 15) / 1000;
        maxWallet = (TOTAL_SUPPLY * 15) / 1000;
        swapTokensAtAmount = (TOTAL_SUPPLY * 1) / 1000;

        buyTeamFee = 20;
        buyVaultFee = 1;
        buyLiquidityFee = 3;
        buyTotalFees = buyTeamFee + buyVaultFee + buyLiquidityFee;

        sellTeamFee = 20;
        sellVaultFee = 1;
        sellLiquidityFee = 3;
        sellTotalFees = sellTeamFee + sellVaultFee + sellLiquidityFee;

        previousFee = sellTotalFees;

        marketingWallet = _teamWallet;
        developmentWallet = _owner;
        liquidityWallet = _teamWallet;

        excludeFromFees(_owner, true);
        excludeFromFees(_deployer, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(developmentWallet, true);
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(uniswapV2Router), true);

        excludeFromMaxTransaction(_owner, true);
        excludeFromMaxTransaction(_deployer, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(developmentWallet, true);
        excludeFromMaxTransaction(liquidityWallet, true);

        _mint(_owner, (TOTAL_SUPPLY * 10) / 100);
        _mint(address(this), (TOTAL_SUPPLY * 90) / 100);
        _transferOwnership(_deployer);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function igniteXXX() external payable onlyOwner {
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        tradingActive = true;
        swapEnabled = true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxWalletAndTxnAmount(
        uint256 newTxnNum,
        uint256 newMaxWalletNum
    ) external onlyOwner {
        require(
            newTxnNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        require(
            newMaxWalletNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _developmentFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        buyTeamFee = _marketingFee;
        buyVaultFee = _developmentFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyTeamFee + buyVaultFee + buyLiquidityFee;
        require(buyTotalFees <= 20, "ERC20: Must keep fees at 20% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _developmentFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        sellTeamFee = _marketingFee;
        sellVaultFee = _developmentFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellTeamFee + sellVaultFee + sellLiquidityFee;
        previousFee = sellTotalFees;
        require(sellTotalFees <= 20, "ERC20: Must keep fees at 20% or less");
    }

    function updateMarketingWallet(address _marketingWallet)
        external
        onlyOwner
    {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit marketingWalletUpdated(marketingWallet, oldWallet);
    }

    function updateDevelopmentWallet(address _developmentWallet)
        external
        onlyOwner
    {
        require(_developmentWallet != address(0), "ERC20: Address 0");
        address oldWallet = developmentWallet;
        developmentWallet = _developmentWallet;
        emit developmentWalletUpdated(developmentWallet, oldWallet);
    }

    function updateLiquidityWallet(address _liquidityWallet)
        external
        onlyOwner
    {
        require(_liquidityWallet != address(0), "ERC20: Address 0");
        address oldWallet = liquidityWallet;
        liquidityWallet = _liquidityWallet;
        emit liquidityWalletUpdated(liquidityWallet, oldWallet);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
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

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress &&
            !swapping
        ) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "ERC20: Trading is not active."
                );
            }

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
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

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellTeamFee) / sellTotalFees;
                tokensForDevelopment += (fees * sellVaultFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyTeamFee) / buyTotalFees;
                tokensForDevelopment += (fees * buyVaultFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
        sellTotalFees = previousFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDevelopment;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );

        uint256 ethForDevelopment = ethBalance.mul(tokensForDevelopment).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance -
            ethForMarketing -
            ethForDevelopment;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDevelopment = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(developmentWallet).call{value: ethForDevelopment}(
            ""
        );

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
}
