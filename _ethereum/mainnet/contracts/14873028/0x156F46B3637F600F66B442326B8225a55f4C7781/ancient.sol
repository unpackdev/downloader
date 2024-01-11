// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ANCIENT is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private router;

    mapping (address => uint) private antiMEV;

    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isExcludedFromFee;
    mapping (address => bool) private isBot;

    bool public isTradingOpened;
    bool private isSwapping;
    bool private isInSwap = false;
    bool private isSwapEnabled = false;
    bool public isAntiMEVEnabled = false;

    string private constant _name = "The Truths Of The Noble Ones";
    string private constant _symbol = "ANCIENT";

    uint8 private constant _decimals = 18;

    uint256 private constant _tTotal = 1e12 * (10**_decimals);
    uint256 public maxBuyAmount = _tTotal;
    uint256 public maxSellAmount = _tTotal;
    uint256 public maxWalletAmount = _tTotal;
    uint256 private tradingOpenedBlock = 0;
    uint256 private buyMarketingFee = 2;
    uint256 private previousBuyMarketingFee = buyMarketingFee;
    uint256 private buyLiquidityFee = 2;
    uint256 private previousBuyLiquidityFee = buyLiquidityFee;
    uint256 private sellMarketingFee = 3;
    uint256 private previousSellMarketingFee = sellMarketingFee;
    uint256 private sellLiquidityFee = 3;
    uint256 private previousSellLiquidityFee = sellLiquidityFee;
    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;
    uint256 private swapTokensThreshold = 0;

    address payable private marketingWallet;
    address payable private liquidityWallet;
    address private pair;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    modifier lockTheSwap {
        isInSwap = true;
        _;
        isInSwap = false;
    }
    
    constructor (address mktgWallet, address liqWallet) {
        marketingWallet = payable(mktgWallet);
        liquidityWallet = payable(liqWallet);
        _rOwned[_msgSender()] = _tTotal;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[liquidityWallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setisAntiMEVEnabled(bool onoff) external onlyOwner() {
        isAntiMEVEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) external onlyOwner(){
        isSwapEnabled = onoff;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Error: transfer from the zero address");
        require(to != address(0), "Error: transfer to the zero address");
        require(amount > 0, "Error: Transfer amount must be greater than zero");
        bool takeFee = false;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !isSwapping) {
            require(!isBot[from] && !isBot[to]);

            if (isAntiMEVEnabled){
                if (to != address(router) && to != address(pair)){
                    require(antiMEV[tx.origin] < block.number - 1 && antiMEV[to] < block.number - 1, "Error: Transfer delay enabled. Try again later.");
                    antiMEV[tx.origin] = block.number;
                    antiMEV[to] = block.number;
                }
            }

            takeFee = true;
            if (from == pair && to != address(router) && !isExcludedFromFee[to]) {
                require(isTradingOpened, "Error: Trading is not allowed yet.");
                require(amount <= maxBuyAmount, "Error: Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Error: Transfer amount exceeds the maximum wallet amount.");
            }
            
            if (to == pair && from != address(router) && !isExcludedFromFee[from]) {
                require(isTradingOpened, "Error: Trading is not allowed yet.");
                require(amount <= maxSellAmount, "Error: Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensThreshold) && shouldSwap;

        if (canSwap && isSwapEnabled && !isSwapping && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            isSwapping = true;
            swapNLiq();
            isSwapping = false;
        }

        _tokenTransfer(from,to,amount,takeFee, shouldSwap);
    }

    function swapNLiq() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensThreshold * 5) {
            contractBalance = swapTokensThreshold * 5;
        }
        
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing;
        
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        marketingWallet.transfer(amount);
    }

    function removeAllFee() private {
        if(buyMarketingFee == 0 && buyLiquidityFee == 0 && sellMarketingFee == 0 && sellLiquidityFee == 0) return;
        
        previousBuyMarketingFee = buyMarketingFee;
        previousBuyLiquidityFee = buyLiquidityFee;
        previousSellMarketingFee = sellMarketingFee;
        previousSellLiquidityFee = sellLiquidityFee;
        
        buyMarketingFee = 0;
        buyLiquidityFee = 0;
        sellMarketingFee = 0;
        sellLiquidityFee = 0;
    }
    
    function restoreAllFee() private {
        buyMarketingFee = previousBuyMarketingFee;
        buyLiquidityFee = previousBuyLiquidityFee;
        sellMarketingFee = previousSellMarketingFee;
        sellLiquidityFee = previousSellLiquidityFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            removeAllFee();
        } else {
            amount = takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 totalFees;
        uint256 mktgFee;
        uint256 liqFee;
        
        totalFees = getTotalFees(isSell);
        if (isSell) {
            mktgFee = sellMarketingFee;
            liqFee = sellLiquidityFee;
        } else {
            mktgFee = buyMarketingFee;
            liqFee = buyLiquidityFee;
        }

        uint256 fees = amount.mul(totalFees).div(100);
        tokensForMarketing += fees * mktgFee / totalFees;
        tokensForLiquidity += fees * liqFee / totalFees;
            
        if(fees > 0) {
            _transferStandard(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    function getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return sellMarketingFee + sellLiquidityFee;
        }
        return buyMarketingFee + buyLiquidityFee;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function manualSwap() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForETH(contractBalance);
    }
    
    function manualSend() public onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
    
    function enableTrading() external onlyOwner {
        require(!isTradingOpened,"trading is already open");
        IUniswapV2Router02 _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        router = _router;
        _approve(address(this), address(router), _tTotal);
        pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        isSwapEnabled = true;
        isAntiMEVEnabled = true;
        maxBuyAmount = 1e10 * (10**_decimals);
        maxSellAmount = 1e10 * (10**_decimals);
        maxWalletAmount = 2e10 * (10**_decimals);
        swapTokensThreshold = 5e8 * (10**_decimals);
        isTradingOpened = true;
        tradingOpenedBlock = block.number;
        IERC20(pair).approve(address(router), type(uint).max);
    }

    function setLimits(uint256 maxBuy, uint256 maxSell, uint256 maxWallet) public onlyOwner {
        require(maxBuy >= 1e8 * (10**_decimals), "maxBuy cannot be lower than 0.01% total supply.");
        require(maxSell >= 1e8 * (10**_decimals), "maxSell cannot be lower than 0.01% total supply.");
        require(maxWallet >= 1e9 * (10**_decimals), "maxWallet cannot be lower than 0.1% total supply.");
        maxBuyAmount = maxBuy;
        maxSellAmount = maxSell;
        maxWalletAmount = maxWallet;
    }

    function disableLimits() public onlyOwner {
        maxBuyAmount = _tTotal;
        maxSellAmount = _tTotal;
        maxWalletAmount = _tTotal;
        isAntiMEVEnabled = false;
    }
    
    function setSwapTokensThresholdAmount(uint256 amount) public onlyOwner {
        require(amount >= 1e7 * (10**_decimals), "Swap threshold cannot be lower than 0.001% total supply.");
        require(amount <= 5e9 * (10**_decimals), "Swap threshold cannot be higher than 0.5% total supply.");
        swapTokensThreshold = amount;
    }

    function setMarketingWalletAddy(address wallet) public onlyOwner {
        require(wallet != address(0), "Wallet address cannot be 0");
        isExcludedFromFee[marketingWallet] = false;
        marketingWallet = payable(wallet);
        isExcludedFromFee[marketingWallet] = true;
    }

    function setLiquidityWalletAddy(address wallet) public onlyOwner {
        require(wallet != address(0), "Wallet address cannot be 0");
        isExcludedFromFee[liquidityWallet] = false;
        liquidityWallet = payable(wallet);
        isExcludedFromFee[liquidityWallet] = true;
    }

    function setFeeExclusion(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = exempt;
        }
    }
    
    function setBots(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = exempt;
        }
    }

    function setBuyFee(uint256 buyMktgFee, uint256 buyLiqFee) external onlyOwner {
        require(buyMktgFee + buyLiqFee <= 10, "Must keep buy taxes below 10%");
        buyMarketingFee = buyMktgFee;
        buyLiquidityFee = buyLiqFee;
    }

    function setSellFee(uint256 sellMktgFee, uint256 sellLiqFee) external onlyOwner {
        require(sellMktgFee + sellLiqFee <= 10, "Must keep sell taxes below 10%");
        sellMarketingFee = sellMktgFee;
        sellLiquidityFee = sellLiqFee;
    }
}