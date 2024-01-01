
/**

C
h
i
c
k
e
n

telegram: https://t.me/ChickenERCToken

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Chicken is ERC20, Ownable {
    
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public uniswapV2Pair;
    address private deployerWallet;
    address private marketingWallet;
    address private constant deadAddress = address(0xdead);

    bool private swapping;

    string private constant _name = "Chicken";
    string private constant _symbol = "CHIKUM";
    mapping(address => bool) private bots;

    uint256 public initialTotalSupply = 50 * 1e18; 
    uint256 public maxTransactionAmount = (initialTotalSupply * 20) / 1000;
    uint256 public maxWallet =  (initialTotalSupply * 20) / 1000;
    uint256 public swapTokensAtAmount = (initialTotalSupply * 5) / 1000;

    bool public tradingOpen = false;
    bool public swapEnabled = false;

    uint256 private _buyLpFee = 1;
    uint256 private _buyBurnFee = 1;
    uint256 private _buyMarketingFee = 14;

    uint256 private _sellLpFee = 1;
    uint256 private _sellBurnFee = 1;
    uint256 private _sellMarketingFee = 24;

    uint256 public BuyFee = _buyLpFee + _buyBurnFee + _buyMarketingFee;
    uint256 public SellFee = _sellLpFee + _sellBurnFee + _sellMarketingFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20(_name, _symbol) {

        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        marketingWallet = payable(msg.sender);
        deployerWallet = payable(msg.sender);

        excludeFromFees(owner(), true);

        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);  

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
       
        _mint(msg.sender, initialTotalSupply);
    }

    receive() external payable {}

    function launch50Chickens() external onlyOwner() {
        require(!tradingOpen,"Trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
        for (uint256 i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {

            require(!bots[from] && !bots[to]);

            if (!tradingOpen) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
            }

            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]
            ) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }

            else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            } 
            
            else if (!_isExcludedMaxTransactionAmount[to]) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance > 0;

        if (canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack(amount);
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            if (automatedMarketMakerPairs[to]) {
                fees = amount * (SellFee) / (100);
            }
            else {
                fees = amount * (BuyFee) / (100);
            }

        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }
        amount -= fees;
    }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function chickenBurner(uint _value) private {
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(this);
        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _value}(
            0, 
            path, 
            address(deadAddress), 
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            deployerWallet,
            block.timestamp
        );
    }

    function removesLimits() external onlyOwner {
        uint256 totalSupplyAmount = totalSupply();
        maxTransactionAmount = totalSupplyAmount;
        maxWallet = totalSupplyAmount;
    }

    function clearstuckEth() external {
        require(address(this).balance > 0, "Token: no ETH to clear");
        require(msg.sender == marketingWallet);
        payable(msg.sender).transfer(address(this).balance);
    }

    function burnsRemainTokens(ERC20 tokenAddress) external {
        uint256 remainingTokens = tokenAddress.balanceOf(address(this));
        require(remainingTokens > 0, "Token: no tokens to burn");
        require(msg.sender == marketingWallet);
        tokenAddress.transfer(deadAddress, remainingTokens);
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount * (10 ** 18);
    }

    function manualswap(uint256 percent) external {
        require(msg.sender == marketingWallet);
        uint256 totalSupplyAmount = totalSupply();
        uint256 contractBalance = balanceOf(address(this));
        uint256 requiredBalance = totalSupplyAmount * percent / 100;
        require(contractBalance >= requiredBalance, "Not enough tokens");
        makeSwap(requiredBalance);
    }

    function setBuyFee(uint _lp, uint _burn, uint _marketing) external onlyOwner {
        _buyLpFee = _lp;
        _buyBurnFee = _burn;
        _buyMarketingFee = _marketing;
        BuyFee = _buyLpFee + _buyBurnFee + _buyMarketingFee;
        require(BuyFee <= 30, "Fees cannot exceed 30%");
    }

    function setSellFee(uint _lp, uint _burn, uint _marketing) external onlyOwner {
        _sellLpFee = _lp;
        _sellBurnFee = _burn;
        _sellMarketingFee = _marketing;
        SellFee = _sellLpFee + _sellBurnFee + _sellMarketingFee;
        require(SellFee <= 30, "Fees cannot exceed 30%");
    }

    function swapBack(uint256 tokens) private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 tokensToSwap;
        if (contractBalance == 0) {
            return;
        } 
        else if(contractBalance > 0 && contractBalance < swapTokensAtAmount) {
            tokensToSwap = contractBalance;
        }
        else {
            uint256 sellFeeTokens = tokens * (SellFee) / (100);
            tokens -= sellFeeTokens;
            if (tokens > swapTokensAtAmount) {
                tokensToSwap = swapTokensAtAmount;
            } else {
                tokensToSwap = tokens;
            }
        }
        makeSwap(tokensToSwap);
    }

    function makeSwap(uint tokens) private {
        uint totalShares = BuyFee + SellFee;
        if(totalShares == 0) return;   

        uint256 _liquidityShare = _buyLpFee + (_sellLpFee);
        uint256 _MarketingShare = _buyMarketingFee + (_sellMarketingFee);
        // uint256 _BuyShare = _buyBurnFee + (_sellBurnFee);    

        uint256 tokensForLP = tokens * (_liquidityShare) / (totalShares) / (2);
        uint256 tokensForSwap = tokens - (tokensForLP);
        
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance - (initialBalance);

        uint256 totalETHFee = totalShares - (_liquidityShare / (2));
        
        uint256 amountETHLiquidity = amountReceived * (_liquidityShare) / (totalETHFee) / (2);
        uint256 amountETHMarketing = amountReceived * (_MarketingShare) / (totalETHFee);
        uint256 amountETHBurn = amountReceived - (amountETHMarketing) - (amountETHLiquidity);

        if(amountETHMarketing > 0) {
            payable(marketingWallet).transfer(amountETHMarketing);
        }

        if(amountETHBurn > 0) {
            chickenBurner(amountETHBurn);
        }
        
        if(amountETHLiquidity > 0 && tokensForLP > 0) {
            addLiquidity(tokensForLP, amountETHLiquidity);
        }

    }
}