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

// SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.20;

pragma experimental ABIEncoderV2;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract SLING is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public mktgWallet;
    address public rewardWallet;
    address public operationsWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) public blocked;

    address public routerCA;
    uint256 public buyTotalFees;
    uint256 public buyMktgFee;
    uint256 public buyRewardFee;
    uint256 public buyOperationsFee;

    uint256 public sellTotalFees;
    uint256 public sellMktgFee;
    uint256 public sellRewardFee;
    uint256 public sellOperationsFee;

    uint256 public tokensForMktg;
    uint256 public tokensForLiquidity;
    uint256 public tokensForOperations;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event WalletsUpdated(
        address indexed newMktgWallet,
        address indexed newOperationsWallet,
        address indexed newRewardWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(address _router,address _mktgWallet,address _rewardWallet,address _operationsWallet) ERC20("BetSlinger", "SLING") Ownable(msg.sender) {
        routerCA = _router;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // launch buy fees
        uint256 _buyMktgFee = 4;
        uint256 _buyRewardFee = 1;
        uint256 _buyOperationsFee = 10;
        
        // launch sell fees
        uint256 _sellMktgFee = 8;
        uint256 _sellRewardFee = 1;
        uint256 _sellOperationsFee = 11;

        uint256 totalSupply = 1_000_000 * 1e18;

        maxTransactionAmount = totalSupply * 1 / 100; // 1% max txn
        maxWallet = totalSupply * 1 / 100; // 1% max wallet
        swapTokensAtAmount = totalSupply * 1 / 100; // 1% swap wallet

        buyMktgFee = _buyMktgFee;
        buyRewardFee = _buyRewardFee;
        buyOperationsFee = _buyOperationsFee;
        buyTotalFees = buyMktgFee + buyRewardFee + buyOperationsFee;

        sellMktgFee = _sellMktgFee;
        sellRewardFee = _sellRewardFee;
        sellOperationsFee = _sellOperationsFee;
        sellTotalFees = sellMktgFee + sellRewardFee + sellOperationsFee;

        mktgWallet = _mktgWallet; 
        rewardWallet = _rewardWallet; 
        operationsWallet = _operationsWallet;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() virtual external onlyOwner {
        require(!tradingActive, "Token launched");
        tradingActive = true;
        swapEnabled = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 25) / 10000,
            "Swap amount cannot be lower than 0.25% total supply."
        );
        require(
            newAmount <= (totalSupply() * 20) / 1000,
            "Swap amount cannot be higher than 2% total supply."
        ); 
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _mktgFee,
        uint256 _rewardFee,
        uint256 _operationsFee
    ) external onlyOwner {
        buyMktgFee = _mktgFee;
        buyRewardFee = _rewardFee;
        buyOperationsFee = _operationsFee;
        buyTotalFees = buyMktgFee + buyRewardFee + buyOperationsFee;
        require(buyTotalFees <= 99);
    }

    function updateSellFees(
        uint256 _mktgFee,
        uint256 _rewardFee,
        uint256 _operationsFee
    ) external onlyOwner {
        sellMktgFee = _mktgFee;
        sellRewardFee = _rewardFee;
        sellOperationsFee = _operationsFee;
        sellTotalFees = sellMktgFee + sellRewardFee + sellOperationsFee;
        require(sellTotalFees <= 99); 
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
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

    function updateWallets(address newmktgWallet,address newOperationsWallet,address newRewardWallet) external onlyOwner {
        emit WalletsUpdated(newmktgWallet,newOperationsWallet,newRewardWallet);
        mktgWallet = newmktgWallet;
        operationsWallet = newOperationsWallet;
        rewardWallet = newRewardWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    event BoughtEarly(address indexed sniper);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) virtual internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blocked[from], "Sniper blocked");

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

                if(from == address(uniswapV2Pair) &&  
                to != routerCA && to != address(this) && to != address(uniswapV2Pair)){
                    blocked[to] = true;
                    emit BoughtEarly(to);
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
                tokensForLiquidity += (fees * sellRewardFee) / sellTotalFees;
                tokensForMktg += (fees * sellMktgFee) / sellTotalFees;
                tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyRewardFee) / buyTotalFees;
                tokensForMktg += (fees * buyMktgFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
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

    function multiBlock(address[] calldata blockees, bool shouldBlock) external onlyOwner {
        for(uint256 i = 0;i<blockees.length;i++){
            address blockee = blockees[i];
            if(blockee != address(this) && 
               blockee != routerCA && 
               blockee != address(uniswapV2Pair))
                blocked[blockee] = shouldBlock;
        }
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
            rewardWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMktg +
            tokensForOperations;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMktg = ethBalance.mul(tokensForMktg).div(totalTokensToSwap);
        uint256 ethForOperations = ethBalance.mul(tokensForOperations).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMktg- ethForOperations;

        tokensForLiquidity = 0;
        tokensForMktg = 0;
        tokensForOperations = 0;


        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
        (success, ) = address(operationsWallet).call{value: ethForOperations}("");
        (success, ) = address(mktgWallet).call{value: address(this).balance}("");
    }
}