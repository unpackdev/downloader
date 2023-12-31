// SPDX-License-Identifier: MIT

/**http://t.me/dilloncoin
https://twitter.com/dilloncoin
*/

pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address ZERO = 0x0000000000000000000000000000000000000000;

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(ZERO);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != ZERO, "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract DILLONCOIN is IERC20, Ownable {

    address private WETH;

    string private constant _name = "Dillon Coin";
    string private constant _symbol = "DLLN";
    uint8 private constant _decimals = 18;
    
    uint256 public _totalSupply = 1 * 10**9 * (10 ** _decimals);
    uint256 public swapThreshold = _totalSupply / 1000; // Starting at 0.1%
    uint256 public maxWallet = _totalSupply / 50; // Starting at 2%

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping(address => bool) public isWalletExempt;

    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint[2] taxesCollected = [0, 0];

    uint256 public launchedAt;
    address public liquidityPool = 0x4dD97E73337FE5c8DE3277797A39E1b4859B246a;

    // All fees are in basis points (100 = 1%)
    uint256 private buyMkt = 100;
    uint256 private sellMkt = 400;
    uint256 private buyLP = 100;
    uint256 private sellLP = 100;

    uint256 _baseBuyFee = buyMkt + buyLP;
    uint256 _baseSellFee = sellMkt + sellLP;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address public marketingWallet = payable(0x0BB04ec742985B3A96afA9EEe6B0a9Dbd9f98B1e);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;

    //Event Logs
    event LiquidityPoolUpdated(address indexed _newPool);
    event MarketingWalletUpdated(address indexed _newWallet);
    event RouterUpdated(IDEXRouter indexed _newRouter);
    event BuyFeesUpdated(uint256 _newMkt, uint256 _newLp);
    event SellFeesUpdated(uint256 _neMkt, uint256 _newLp);
    event FeeExemptionChanged(address indexed _exemptAddress, bool _exempt);
    event SwapbackSettingsChanged(bool _enabled, uint256 _newSwapbackAmount);
    event MaxWalletUpdated(uint256 _newMaxWallet);
    event WalletExemptionChanged(address indexed _exemptAddress, bool _exempt);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[owner()] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[address(this)] = true;

        isWalletExempt[owner()] = true;
        isWalletExempt[marketingWallet] = true;
        isWalletExempt[DEAD] = true;
        isWalletExempt[pair] = true;

        _balances[owner()] = _totalSupply;
    
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function launchSequence() external onlyOwner {
	    require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        tradingOpen = true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function baseBuyFee() external view returns (uint256) {return _baseBuyFee; }
    function baseSellFee() external view returns (uint256) {return _baseSellFee; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

//Transfer Functions

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!isFeeExempt[sender] && !isFeeExempt[recipient]) { require(tradingOpen, "Trading not active"); }
        if(!isWalletExempt[recipient]) {
            require(_balances[recipient] + amount <= maxWallet || isFeeExempt[sender], "Exceeds Max Wallet");
        }
        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }
        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient] + finalAmount;

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }  

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }  

//Tax Functions

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 mktTaxB = amount * buyMkt / 10000;
	    uint256 mktTaxS = amount * sellMkt / 10000;
        uint256 lpTaxB = amount * buyLP / 10000;
	    uint256 lpTaxS = amount * sellLP / 10000;
        uint256 taxToGet;

	    if(sender == pair && recipient != address(pair) && !isFeeExempt[recipient]) {
            taxToGet = mktTaxB + lpTaxB;
	        addTaxCollected(mktTaxB, lpTaxB);
	    }

	    if(!inSwapAndLiquify && sender != pair && tradingOpen) {
	        taxToGet = mktTaxS + lpTaxS;
	        addTaxCollected(mktTaxS, lpTaxS);
	    }

        _balances[address(this)] = _balances[address(this)] + taxToGet;
        emit Transfer(sender, address(this), taxToGet);

        return amount - taxToGet;
    }

    function addTaxCollected(uint mkt, uint lp) internal {
        taxesCollected[0] += mkt;
        taxesCollected[1] += lp;
    }

//LP and Swapback Functions

    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityPool,
            block.timestamp
        );
    }

    function swapBack() internal lockTheSwap {
    
        uint256 tokenBalance = _balances[address(this)];
        uint256 _totalCollected = taxesCollected[0] + taxesCollected[1];
        uint256 mktShare = taxesCollected[0];
        uint256 lpShare = taxesCollected[1];
        uint256 tokensForLiquidity = lpShare / 2;  
        uint256 amountToSwap = tokenBalance - tokensForLiquidity;

        swapTokensForETH(amountToSwap);

        uint256 totalETHBalance = address(this).balance;
        uint256 ETHForMkt = totalETHBalance * mktShare / _totalCollected;
        uint256 ETHForLiquidity = totalETHBalance * lpShare / _totalCollected / 2;
      
        if (totalETHBalance > 0) {
            payable(marketingWallet).transfer(ETHForMkt);
        }
  
        if (tokensForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ETHForLiquidity);
        }

	    delete taxesCollected;
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

// Update/Change Functions

    function changeFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit FeeExemptionChanged(holder, exempt);
    }

    function changeWalletExempt(address holder, bool exempt) external onlyOwner {
        isWalletExempt[holder] = exempt;
        emit WalletExemptionChanged(holder, exempt);
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "Cannot be set to zero address");
        marketingWallet = payable(newMarketingWallet);
        isFeeExempt[marketingWallet] = true;
        isWalletExempt[marketingWallet] = true;
        emit MarketingWalletUpdated(newMarketingWallet);
    }

    function setLiquidityPool(address newLiquidityPool) external onlyOwner {
        require(newLiquidityPool != address(0), "Cannot be set to zero address");
        liquidityPool = newLiquidityPool;
        emit LiquidityPoolUpdated(newLiquidityPool);
    }

    function changeSwapBackSettings(bool enableSwapback, uint256 newSwapbackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapback;
        swapThreshold = newSwapbackLimit;
        emit SwapbackSettingsChanged(enableSwapback, newSwapbackLimit);
    }

    function updateMaxWallet(uint256 newMaxWallet) public onlyOwner {
	    require(newMaxWallet >= (_totalSupply / 200), "Max should be greater than 0.5%");
	    maxWallet = newMaxWallet;
        emit MaxWalletUpdated(newMaxWallet);
    }

    function updateBuyFees(uint256 newBuyMktFee, uint256 newBuyLpFee) public onlyOwner {
	    require(newBuyMktFee + newBuyLpFee <= 1000, "Fees Too High");
	    buyMkt = newBuyMktFee;
	    buyLP = newBuyLpFee;
        emit BuyFeesUpdated(newBuyMktFee, newBuyLpFee);
    }
    
    function updateSellFees(uint256 newSellMktFee,uint256 newSellLpFee) public onlyOwner {
	    require(newSellMktFee + newSellLpFee <= 1000, "Fees Too High");
	    sellMkt = newSellMktFee;
	    sellLP = newSellLpFee;
        emit SellFeesUpdated(newSellMktFee, newSellLpFee);
    }

    function updateRouter(IDEXRouter _newRouter) external onlyOwner {
        require(_newRouter != IDEXRouter(ZERO), "Cannot be set to zero address");
        require(_newRouter != IDEXRouter(DEAD), "Cannot be set to zero address");
        router = _newRouter;
        emit RouterUpdated(_newRouter);
    }

    function clearStuckETH() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) { 
            payable(marketingWallet).transfer(contractETHBalance);
    	}
    }

    function clearStuckTokens(address contractAddress) external onlyOwner {
        IERC20 erc20Token = IERC20(contractAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(marketingWallet, balance);
        if(contractAddress == address(this)) { delete taxesCollected; }
    }

    function massDistributeTokens(address[] calldata _airdropAddresses, uint _amtPerAddress) external onlyOwner {
        uint amtPerAddress = _amtPerAddress * (10 ** _decimals);
	    for (uint i = 0; i < _airdropAddresses.length; i++) {
	        IERC20(address(this)).transfer(_airdropAddresses[i], amtPerAddress);
        }
    }

    function distributeTokensByAmount(address[] calldata _airdropAddresses, uint[] calldata _airdropAmounts) external onlyOwner {
	    for (uint i = 0; i < _airdropAddresses.length; i++) {
            uint airdropAmount = _airdropAmounts[i] * (10 ** _decimals);
	        IERC20(address(this)).transfer(_airdropAddresses[i], airdropAmount);
        }
    }
}