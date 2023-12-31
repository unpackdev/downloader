/**
WEBSITE: https://methereum.org/
TWITTER: https://twitter.com/methereum69
TELEGRAM: https://t.me/METHEREUEM
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

//import "./console.sol";

contract METH is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public constant deadAddress = address(0x000000000000000000000000000000000000dEaD);

    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;
    uint256 public swapTokensAtMultiplier;
    
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    bool public blacklistRenounced = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => bool) blacklisted;

    struct Taxes {
        uint256 corruption;
        uint256 liquidity;
        uint256 cooking;   
    }

    Taxes public taxes = Taxes(1, 0, 1);
    Taxes public sellTaxes = Taxes(1, 0, 1);

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public tokensForCorruption;
    uint256 public tokensForLiquidity;
    uint256 public tokensForCooking;

    address private corruptionWallet;
    address private cookingWallet;

    /******************/

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    bool public preListingPhase = true;
    mapping(address => bool) public preListingTransferrable;

    event UpdateUniswapV2Router(address indexed newAddress,address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event CorruptionWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event CookingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("METHEREUM", "METH") {

        corruptionWallet = address(0x90f91bA79aAfEfdcFc0b5fFFb7F0b61526667b19);
        cookingWallet = address(0x60FaeAef5c85CD38892c7107a60CBDD604F8C55d);
        address routerAddress_  = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress_);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(routerAddress_), true);

        uint256 totalSupply =  100 * 1e9 * 1e18; // 100 billions

        maxTransactionAmount = totalSupply * 10 / 1000; // 1% maxtxn
        maxWallet = totalSupply * 10 / 1000; // 1% maxw 

        swapTokensAtMultiplier = 20; //this set max swap amount to 20 times the swapTokensAtAmount
        swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swapw

        buyTotalFees = taxes.corruption + taxes.liquidity + taxes.cooking;
        sellTotalFees = sellTaxes.corruption + sellTaxes.liquidity + sellTaxes.cooking;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(corruptionWallet, true);
        excludeFromFees(cookingWallet, true);

        excludeFromMaxTransaction(corruptionWallet, true);
        excludeFromMaxTransaction(cookingWallet, true);

        preListingTransferrable[owner()] = true;

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
        preListingPhase = false;
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

    function UpdateBuyTaxes(
        uint256 _corruption,
        uint256 _liquidity,
        uint256 _cooking
    ) external onlyOwner {
        taxes = Taxes(_corruption, _liquidity, _cooking);
        buyTotalFees = taxes.corruption + taxes.liquidity + taxes.cooking;
    }

    function SetSellTaxes(
        uint256 _corruption,
        uint256 _liquidity,
        uint256 _cooking
    ) external onlyOwner {
        sellTaxes = Taxes(_corruption, _liquidity, _cooking);
        sellTotalFees = sellTaxes.corruption + sellTaxes.liquidity + sellTaxes.cooking;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.5%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1.0%"
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

    function updateCorruptionWallet(address newWallet) external onlyOwner {
        emit CorruptionWalletUpdated(newWallet, corruptionWallet);
        corruptionWallet = newWallet;
    }

    function updateCookingWallet(address newWallet) external onlyOwner {
        emit CookingWalletUpdated(newWallet, cookingWallet);
        cookingWallet = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //console.log("Transferring from %s to %s %s tokens", msg.sender, to, amount);

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from],"Sender blacklisted");
        require(!blacklisted[to],"Receiver blacklisted");

        if (preListingPhase) {
            require(preListingTransferrable[from], "Not authorized to transfer pre-listing.");
        }

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

        /*console.log("from: %s and to: %s", from, to);
        console.log("!automatedMarketMakerPairs[from] %s", !automatedMarketMakerPairs[from]);
        console.log("!automatedMarketMakerPairs[to] %s", !automatedMarketMakerPairs[to]);*/

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] && //true only during token sell or user wallet to user wallet transfer
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
                tokensForLiquidity += (fees * sellTaxes.liquidity) / sellTotalFees;
                tokensForCooking += (fees * sellTaxes.cooking) / sellTotalFees;
                tokensForCorruption += (fees * sellTaxes.corruption) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * taxes.liquidity) / buyTotalFees;
                tokensForCooking += (fees * taxes.cooking) / buyTotalFees;
                tokensForCorruption += (fees * taxes.corruption) / buyTotalFees;
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
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForCorruption + tokensForCooking;
        bool success;
 
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
 
        if(contractBalance > swapTokensAtAmount * swapTokensAtMultiplier){
          contractBalance = swapTokensAtAmount * swapTokensAtMultiplier;
        }
 
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;
 
        swapTokensForEth(amountToSwapForETH); 
 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
 
        uint256 ethForCorruption = ethBalance.mul(tokensForCorruption).div(totalTokensToSwap);
        uint256 ethForCooking = ethBalance.mul(tokensForCooking).div(totalTokensToSwap);
 
        uint256 ethForLiquidity = ethBalance - ethForCorruption - ethForCooking;
 
        tokensForLiquidity = 0;
        tokensForCorruption = 0;
        tokensForCooking = 0;
 
        (success,) = address(cookingWallet).call{value: ethForCooking}("");
 
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
 
        (success,) = address(corruptionWallet).call{value: address(this).balance}("");
    }

    function withdrawStuckToken() external onlyOwner {
        uint256 balance = IERC20(address(this)).balanceOf(address(this));
        IERC20(address(this)).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawStuckToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }

    // @dev team renounce blacklist commands
    function renounceBlacklist() public onlyOwner {
        blacklistRenounced = true;
    }

    function blacklist(address _addr) public onlyOwner {
        require(!blacklistRenounced, "Team has revoked blacklist rights");
        require(
            _addr != address(uniswapV2Pair) && _addr != address(uniswapV2Router), 
            "Cannot blacklist token's v2 router or v2 pool."
        );
        blacklisted[_addr] = true;
    }

    // @dev blacklist v3 pools; can unblacklist() down the road to suit project and community
    function blacklistLiquidityPool(address lpAddress) public onlyOwner {
        require(!blacklistRenounced, "Team has revoked blacklist rights");
        require(
            lpAddress != address(uniswapV2Pair) && lpAddress != address(uniswapV2Router), 
            "Cannot blacklist token's v2 router or v2 pool."
        );
        blacklisted[lpAddress] = true;
    }

    // @dev unblacklist address; not affected by blacklistRenounced incase team wants to unblacklist v3 pools down the road
    function unblacklist(address _addr) public onlyOwner {
        blacklisted[_addr] = false;
    }

    function setPreListingTransferable(address _addr, bool isAuthorized) public onlyOwner {
        preListingTransferrable[_addr] = isAuthorized;
        excludeFromFees(_addr, isAuthorized);
        excludeFromMaxTransaction(_addr, isAuthorized);
    }
}