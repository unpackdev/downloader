// SPDX-License-Identifier: GenesisBot.xyz
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract GenesisToken is ERC20, Ownable {
    struct InitParams {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        uint256 maxTradingAmount;
        uint256 maxWalletAmount;
        uint256 swapTokensAtAmount;
        uint256 buyTotalFees;
        uint256 sellTotalFees;
        uint256 burnFee;
        uint256 liquidityFee;
        uint256 devFee;
        uint256 revshareFee;
        address devWallet;
        address revshareWallet;
        uint256 liquidityAmount;
    }

    uint8 private _decimals;

    IUniswapV2Router02 public immutable swapV2Router;
    //ITurnstile public immutable turnstile;
    address public swapV2Pair;
    address public constant DEAD_ADDRESS = address(0xdead);

    bool public swapEnabled = false;
    bool private swapping;

    address public revShareWallet;
    address public devWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxWalletAmount;
    uint256 private initMaxTradingAmount;
    bool private limitsInEffect = true; // internal use only, auto remove base on block time

    bool public tradingActive = false;

    uint256 constant PERCENTAGE_BASE = 10000; //
    uint256 constant GEN_FEE = 30; // fee for GEN Bot: 0.3%
    address constant GEN_WALLET = 0x91FEad7F2B2172e75FfCf4cAdFF5049c9270EE41;

    uint256 public buyTotalFees; // buy fee
    uint256 public sellTotalFees; // sell fee

    // Tax distribution
    uint256 public burnFee;
    uint256 public liquidityFee;
    uint256 public devFee;
    uint256 public revshareFee;

    uint256 public tokensForGen;
    uint256 public totalFees;
    uint256 public totalTaxTokens;
    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) public excludeFromLimits;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // Trading start at
    uint256 block0;

    address private liquidOwner;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier onlyDev() {
        require(msg.sender == devWallet);
        _;
    }

    constructor(
        address routerAddress,
        InitParams memory params
    ) payable ERC20(params.name, params.symbol) {
        // amm swap init
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        swapV2Router = router;

        // Token parameters
        _decimals = params.decimals;
        uint256 totalSupply_ = params.totalSupply * (10 ** _decimals);
        swapTokensAtAmount =
            (totalSupply_ * params.swapTokensAtAmount) /
            PERCENTAGE_BASE; // 0.05%

        initMaxTradingAmount =
            (totalSupply_ * params.maxTradingAmount) /
            PERCENTAGE_BASE; // 0.1%
        maxWalletAmount =
            (totalSupply_ * params.maxWalletAmount) /
            PERCENTAGE_BASE; // 1%

        // Fee distribute: burn: 1, dev: 4
        // tax distribution
        burnFee = params.burnFee;
        liquidityFee = params.liquidityFee;
        devFee = params.devFee;
        revshareFee = params.revshareFee;

        totalFees = burnFee + liquidityFee + devFee + revshareFee;
        // update revshare wallet
        revShareWallet = params.revshareWallet == address(0)
            ? msg.sender
            : params.revshareWallet;

        liquidOwner = msg.sender;

        // 5% fee for buy/sell
        require(
            params.buyTotalFees <= 500 && params.sellTotalFees <= 500,
            "Buy/sell fees must be <= 5%"
        );
        buyTotalFees = params.buyTotalFees;
        sellTotalFees = params.sellTotalFees;
        if (buyTotalFees < GEN_FEE) buyTotalFees += GEN_FEE;
        if (sellTotalFees < GEN_FEE) sellTotalFees += GEN_FEE;

        devWallet = params.devWallet == address(0)
            ? msg.sender
            : params.devWallet;

        // exclude from paying fees or having max transaction amount
        excludeFromLimits[owner()] = true;
        excludeFromLimits[address(this)] = true;
        excludeFromLimits[DEAD_ADDRESS] = true;
        /*
            mint & add liquidity
        */
        // add liquidity
        require(params.liquidityAmount <= PERCENTAGE_BASE);
        uint256 liquidityAmount = (totalSupply_ * params.liquidityAmount) /
            PERCENTAGE_BASE;

        _mint(address(this), liquidityAmount);
        // mint left
        if (liquidityAmount < totalSupply_) {
            _mint(msg.sender, totalSupply_ - liquidityAmount);
        }

        // Approve infinite spending by DEX, to sell tokens collected via tax.
        _approve(address(this), address(swapV2Router), type(uint256).max);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    receive() external payable {}

    // linit will be removed automatically base on blocks
    function maxTradingAmount() public view returns (uint amount) {
        if (limitsInEffect) {
            amount = initMaxTradingAmount;
            if (tradingActive) {
                amount +=
                    ((block.number - block0) * totalSupply()) /
                    PERCENTAGE_BASE;
            }
        }
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyDev returns (bool) {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyDev {
        swapEnabled = enabled;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyDev {
        require(
            pair != swapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        // only limit for trading
        if (
            limitsInEffect && !excludeFromLimits[from] && !excludeFromLimits[to]
        ) {
            if (
                !tradingActive &&
                (automatedMarketMakerPairs[from] ||
                    automatedMarketMakerPairs[to])
            ) {
                require(
                    excludeFromLimits[from] || excludeFromLimits[to],
                    "Trading is not active."
                );
            }

            uint maxTradingAmount_ = maxTradingAmount();

            if (maxTradingAmount_ * 100 > totalSupply()) {
                // remove limit when reach to 1%
                limitsInEffect = false;
            } else {
                if (automatedMarketMakerPairs[from]) {
                    //when buy
                    require(
                        amount <= maxTradingAmount_,
                        "Buy transfer amount exceeds the maxTradingAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Max wallet exceeded"
                    );
                } else if (automatedMarketMakerPairs[to]) {
                    //when sell
                    require(
                        amount <= maxTradingAmount_,
                        "Sell transfer amount exceeds the maxTradingAmount."
                    );
                }
            }
        }
        // uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = totalTaxTokens >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !excludeFromLimits[from] &&
            !excludeFromLimits[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }
        // only take free for trading
        bool takeFee = !swapping &&
            (automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]);

        if (excludeFromLimits[from] || excludeFromLimits[to]) {
            takeFee = false;
        }

        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            (uint256 fees, uint256 geenFees) = _getFees(from, to, amount);
            if (fees > 0) {
                super._transfer(from, address(this), fees);
                tokensForGen += geenFees;
                amount -= fees;
                totalTaxTokens += fees;
            }
        }
        super._transfer(from, to, amount);
    }

    function _getFees(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 fees, uint256 genFees) {
        uint256 tradingFees_;
        if (automatedMarketMakerPairs[_to]) {
            tradingFees_ = sellTotalFees;
        }
        // on buy
        else if (automatedMarketMakerPairs[_from]) {
            tradingFees_ = buyTotalFees;
        }
        if (tradingFees_ < GEN_FEE) tradingFees_ = GEN_FEE;

        fees = (_amount * tradingFees_) / PERCENTAGE_BASE;
        genFees = (fees * GEN_FEE) / tradingFees_;
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapV2Router.WETH();

        // make the swap
        swapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // add the liquidity
        swapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidOwner,
            block.timestamp
        );
    }

    function createPairAndAddLP() public payable onlyOwner {
        // create pair This:ETH
        if (swapV2Pair == address(0)) {
            IUniswapV2Factory factory = IUniswapV2Factory(
                swapV2Router.factory()
            );
            swapV2Pair = factory.createPair(address(this), swapV2Router.WETH());
        }
        _setAutomatedMarketMakerPair(address(swapV2Pair), true);

        addLiquidity(balanceOf(address(this)), address(this).balance);
    }

    function enableTrading() public onlyOwner {
        require(!tradingActive, "Trading is already open");
        // enable trading
        tradingActive = true;
        swapEnabled = true;
        // block zero
        block0 = block.number;
        // renounce owner
        renounceOwnership();
    }

    function openTrading() external payable onlyOwner {
        createPairAndAddLP();
        enableTrading();
    }

    function swapBack() internal virtual {
        uint256 contractBalance = balanceOf(address(this));
        uint256 tokenToSwap_ = contractBalance;
        uint256 tokensForGen_ = tokensForGen;
        if (tokenToSwap_ > swapTokensAtAmount * 20) {
            tokenToSwap_ = swapTokensAtAmount * 20;
            tokensForGen_ = (tokensForGen * tokenToSwap_) / contractBalance;
        }
        if (tokenToSwap_ == 0) return;

        uint256 tokensForFees_ = tokenToSwap_ - tokensForGen_;
        // split tokens for benificiers
        uint256 tokensBurn_;
        uint256 tokensLiquid_;
        uint256 tokensRevshare_;
        uint256 tokensDev_;

        if (totalFees > 0) {
            tokensBurn_ = (tokensForFees_ * burnFee) / totalFees;
            tokensLiquid_ = (tokensForFees_ * liquidityFee) / totalFees;
            tokensRevshare_ = (tokensForFees_ * revshareFee) / totalFees;
            tokensDev_ = (tokensForFees_ * devFee) / totalFees;
            tokensForFees_ =
                tokensBurn_ +
                tokensLiquid_ +
                tokensRevshare_ +
                tokensDev_;
        }

        tokensForGen_ = tokenToSwap_ - tokensForFees_;

        uint256 tokensForAddLiquidity = tokensLiquid_ / 2;

        // swap all token except for Tokens to Add Liquidity and Burnt
        uint256 totalTokensToSwap = tokenToSwap_ -
            tokensForAddLiquidity -
            tokensBurn_;
        if (tokensBurn_ > 0) {
            // transfer to dead
            super._transfer(address(this), DEAD_ADDRESS, tokensBurn_);
        }
        if (totalTokensToSwap > 0) {
            uint256 initEthBalance = address(this).balance;
            swapTokensForEth(totalTokensToSwap);
            uint256 ethBalance = address(this).balance - initEthBalance;

            uint256 ethForGen = (ethBalance * tokensForGen_) /
                totalTokensToSwap;
            uint256 ethForRevshare = (ethBalance * tokensRevshare_) /
                totalTokensToSwap;
            uint256 ethForAddLiquidity = (ethBalance *
                (tokensLiquid_ - tokensForAddLiquidity)) / totalTokensToSwap;

            // send eth to benificiers
            bool success;
            if (ethForGen > 0) {
                (success, ) = address(GEN_WALLET).call{value: ethForGen}("");
            }
            if (ethForRevshare > 0) {
                (success, ) = address(revShareWallet).call{
                    value: ethForRevshare
                }("");
            }
            if (tokensForAddLiquidity > 0 && ethForAddLiquidity > 0) {
                addLiquidity(tokensForAddLiquidity, ethForAddLiquidity);
            }
            if (address(this).balance > 0) {
                (success, ) = address(devWallet).call{
                    value: address(this).balance
                }("");
            }
        }
        // reset token for GEN
        tokensForGen = tokensForGen > tokensForGen_
            ? tokensForGen - tokensForGen_
            : 0;
        totalTaxTokens = 0;
    }

    function withdrawStuckToken(address _token, address _to) external onlyDev {
        require(_token != address(0), "_token address cannot be 0");
        ERC20 token = ERC20(_token);
        token.transfer(_to, token.balanceOf(address(this)));
    }

    function withdrawStuckEth(address toAddr) external onlyDev {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }
}
