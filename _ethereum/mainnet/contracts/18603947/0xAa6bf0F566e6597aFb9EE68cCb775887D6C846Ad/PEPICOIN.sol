//SPDX-License-Identifier: Unlicensed

/* 

 _______  _______  _______  ___  
|       ||       ||       ||   | 
|    _  ||    ___||    _  ||   | 
|   |_| ||   |___ |   |_| ||   | 
|    ___||    ___||    ___||   | 
|   |    |   |___ |   |    |   | 
|___|    |_______||___|    |___| 

*/

pragma solidity 0.8.21;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PEPICOIN is IERC20, Ownable {
    using SafeMath for uint256;
    
    address WETH;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string _name = "PEPI";
    string _symbol = "PEPI";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1 * 10**8 * 10**_decimals; 
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100; // 1%
    uint256 public _maxWalletSize = (_totalSupply * 1) / 100; // 1%  

    mapping (address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isCooldownExempt;    
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
 
    uint256 liquidityFeeBuy = 3; 
    uint256 liquidityFeeSell = 3;

    uint256 TeamFeeBuy = 0;  
    uint256 TeamFeeSell = 0;  

    uint256 marketingFeeBuy = 4;   
    uint256 marketingFeeSell = 15;   

    uint256 reflectionFeeBuy = 1;   
    uint256 reflectionFeeSell = 2;   

    uint256 totalFeeBuy = marketingFeeBuy + liquidityFeeBuy + TeamFeeBuy + reflectionFeeBuy;     
    uint256 totalFeeSell = marketingFeeSell + liquidityFeeSell + TeamFeeSell + reflectionFeeSell; 

    uint256 feeDenominator = 100; 
       
    address autoLPReceiver;
    address marketingReceiver;
    address teamReceiver;

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = false;

    bool public buyCooldownEnabled = true;
    uint8 public CooldownTimerInterval = 10; //seconds
    mapping (address => uint) public CooldownTimer;
    
    bool public claimingFees = true; 
    bool alternateSwaps = true;  
    uint256 smallSwapThreshold = _totalSupply * 1 / 1000; // .1%
    uint256 largeSwapThreshold = _totalSupply * 2 / 1000; // .2%

    uint256 public swapThreshold = smallSwapThreshold;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
	    isTxLimitExempt[pair] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingReceiver] = true;
        isFeeExempt[msg.sender] = true;
        isCooldownExempt[msg.sender] = true;
        isCooldownExempt[DEAD] = true;
        isCooldownExempt[address(this)] = true;

        
        autoLPReceiver = msg.sender; 
        teamReceiver = msg.sender;
        marketingReceiver = msg.sender;

        _rOwned[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return tokenFromReflection(_rOwned[account]); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
       

    function approve(address spender, uint256 amount) 
        public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD && recipient != marketingReceiver && !isTxLimitExempt[recipient]) {
            require(balanceOf(recipient) + amount <= _maxWalletSize, "Max Wallet Exceeded");

        if (sender == pair &&
            buyCooldownEnabled &&
            !isCooldownExempt[recipient]) {
            require(CooldownTimer[recipient] < block.timestamp,"Please wait for between buys");
            CooldownTimer[recipient] = block.timestamp + CooldownTimerInterval;
        }
        
        }
        
        if(!isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount, "Transaction Amount Exceeded");
        }
     
        if (recipient != pair && recipient != DEAD && !isTxLimitExempt[recipient]) {
            require(tradingOpen,"Trading not open yet");
        
        }

        if(shouldSwapBack()){ swapBack(); }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");

        uint256 proportionReceived = shouldTakeFee(sender) && shouldTakeFee(recipient) ? takeFeeInProportions(sender == pair? true : false, sender, recipient, proportionAmount) : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];

    }

     function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function getTotalFeeBuy(bool) public view returns (uint256) {
        return totalFeeBuy;
    }

    function getTotalFeeSell(bool) public view returns (uint256) {
        return totalFeeSell;
    }

    function takeFeeInProportions(bool buying, address sender, address receiver, uint256 proportionAmount) internal returns (uint256) {
        uint256 proportionFeeAmount = buying == true? proportionAmount.mul(getTotalFeeBuy(receiver == pair)).div(feeDenominator) :
        proportionAmount.mul(getTotalFeeSell(receiver == pair)).div(feeDenominator);

        
        uint256 proportionReflected = buying == true? proportionFeeAmount.mul(reflectionFeeBuy).div(totalFeeBuy) :
        proportionFeeAmount.mul(reflectionFeeSell).div(totalFeeSell);

        _totalProportion = _totalProportion.sub(proportionReflected);

        
        uint256 _proportionToContract = proportionFeeAmount.sub(proportionReflected);
        _rOwned[address(this)] = _rOwned[address(this)].add(_proportionToContract);

        emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount.sub(proportionFeeAmount);
    }

     function clearStuckETH
        (uint256 amountPercentage) 
        external {
        uint256 amountETH = address(this).balance;
        payable(teamReceiver).transfer(amountETH * amountPercentage / 100);

        emit ClearStuck(amountPercentage);
    }

     function clearForeignToken
     (address tokenAddress, uint256 tokens) 
     external onlyOwner returns (bool) {
     require(tokenAddress != address(this), "Owner cannot claim native tokens"); 
     if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        emit ClearToken(tokenAddress, tokens);
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
       
    }
  
      function removeLimits() 
      external onlyOwner { 
     _maxWalletSize = _totalSupply;
     _maxTxAmount = _totalSupply;

    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint16 i = 0; i < accounts.length; i++) {
        require(balanceOf(msg.sender) >= amounts[i], "Not enough tokens.");       
        _basicTransfer(msg.sender,accounts[i],amounts[i]);
    }
}
  

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && claimingFees
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFeeSell;
        uint256 _totalFee = totalFeeSell.sub(reflectionFeeSell);
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = _totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFeeSell).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFeeSell).div(totalETHFee);
        uint256 amountETHTeam = amountETH.mul(TeamFeeSell).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(teamReceiver).call{value: amountETHTeam, gas: 30000}("");
             
            if(amountToLiquify > 0) {
             router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLPReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }

        swapThreshold = !alternateSwaps ? swapThreshold : swapThreshold == smallSwapThreshold ? largeSwapThreshold : smallSwapThreshold;
    }

    function setSwapThreshold
    (bool _enabled, uint256 _amountS, uint256 _amountL, bool _alternate) 
    external onlyOwner {
    require(_amountS < (_totalSupply/50), "Cannot set swap amount above 2%");
    require(_amountS > (_totalSupply/100000), "Cannot set swap amount below 0.001%");
    require(_amountL < (_totalSupply/50), "Cannot set swap amount above 2%");
    require(_amountL > (_totalSupply/100000), "Cannot set swap amount below 0.001%");
    alternateSwaps = _alternate;
    claimingFees = _enabled;
    smallSwapThreshold = _amountS;
    largeSwapThreshold = _amountL;
    swapThreshold = smallSwapThreshold;

        emit set_SellAmounts(alternateSwaps, claimingFees, smallSwapThreshold, largeSwapThreshold);
    }

    function enableTrading() 
    public onlyOwner {
    require (!tradingOpen);
    tradingOpen = true;
    
    }

    function setFees
    (uint256 _liquidityFeeBuy, uint256 _reflectionFeeBuy, uint256 _marketingFeeBuy, uint256 _TeamFeeBuy, uint256 _feeDenominator,
    uint256 _liquidityFeeSell, uint256 _reflectionFeeSell, uint256 _marketingFeeSell, uint256 _TeamFeeSell) 
    external onlyOwner {
    liquidityFeeBuy = _liquidityFeeBuy;
    reflectionFeeBuy = _reflectionFeeBuy;
    marketingFeeBuy = _marketingFeeBuy;
    TeamFeeBuy = _TeamFeeBuy;
    totalFeeBuy = liquidityFeeBuy.add(reflectionFeeBuy).add(marketingFeeBuy).add(TeamFeeBuy);

    liquidityFeeSell = _liquidityFeeSell;
    reflectionFeeSell = _reflectionFeeSell;
    marketingFeeSell = _marketingFeeSell;
    TeamFeeSell = _TeamFeeSell;
    totalFeeSell = liquidityFeeSell.add(reflectionFeeSell).add(marketingFeeSell).add(TeamFeeSell);
       
    feeDenominator = _feeDenominator;

    require(totalFeeBuy <= feeDenominator/1,"Cannot set buy fees above 20%"); 
    require(totalFeeSell <=feeDenominator/1,"Cannot set sell fees above 20%"); 
        
     }
     
    function updateMaxWallet
    (uint256 maxWalletHolding) 
    external onlyOwner() {
    require(maxWalletHolding >= 1);
    _maxWalletSize = (_totalSupply * maxWalletHolding ) / 1000;
    emit set_MaxWallet(_maxWalletSize);
    }

    function updateMaxTransaction
    (uint256 maxTransactionSize) 
    external onlyOwner() {
    require(maxTransactionSize >= 1, "Cannot set max TX below .1%");
     _maxTxAmount = (_totalSupply * maxTransactionSize ) / 1000;
    emit set_MaxTransaction(_maxTxAmount);
    
      }
      
    function addTaxExemption
    (address[] calldata addresses, bool status) 
    public onlyOwner {
    for (uint256 i; i < addresses.length; ++i) {
    isFeeExempt[addresses[i]] = status;
        }
    }

    function addTXLimitExemption
    (address[] calldata addresses, bool status)
    public onlyOwner {
    for (uint256 i; i < addresses.length; ++i) {
    isTxLimitExempt[addresses[i]] = status;
        } 
    }

    function addCooldownExempt
    (address holder, bool exempt) 
    external onlyOwner {
    isCooldownExempt[holder] = exempt;
    }

    
    function setPresaleAddress
    (address holder, bool exempt) external onlyOwner {
    isFeeExempt[holder] = exempt;
    isTxLimitExempt[holder] = exempt;
    }
    
    function setTaxReceivers
    (address _marketingReceiver, address _autoLPReceiver, address _TeamReceiver) 
    external onlyOwner {
    marketingReceiver = _marketingReceiver;
    teamReceiver = _TeamReceiver;
    autoLPReceiver = _autoLPReceiver;

    emit set_Receivers(marketingReceiver, teamReceiver, autoLPReceiver);
    }

    function getCirculatingSupply() 
    public view returns (uint256) {
    return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking
    (uint256 accuracy) 
    private view returns (uint256) {
    return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());

    }

    function isOverLiquified
    (uint256 target, uint256 accuracy)
    public view returns (bool) {
    return getLiquidityBacking(accuracy) > target;
    
    }

    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
    event user_exemptfromfees(address Wallet, bool Exempt);
    event user_TxExempt(address Wallet, bool Exempt);
    event ClearStuck(uint256 amount);
    event ClearToken(address tokenAddress, uint256 tokens);
    event set_Receivers(address marketingReceiver, address teamReceiver,address autoLPReceiver);
    event set_MaxWallet(uint256 maxWallet);
    event set_MaxTransaction(uint256 maxTXAmount);
    event set_SellAmounts(bool enabled, bool alternate, uint256 amountS, uint256 amountL);
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}