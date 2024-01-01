//https://t.me/blkrportal
//https://black-rock.vip/
//https://x.com/blkrclub?s=21&t=4--oBQeRIUtk_5S6nPf-Jg



// SPDX-License-Identifier: Unlicensed


pragma solidity 0.8.21;

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

contract BLACKROCK is Ownable, ERC20 {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    

    string constant _name = "Blackrock";
    string constant _symbol = "BLKR";
    uint8 constant _decimals = 9; 
  

    uint256 _totalSupply = 1 * 10**8 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply.mul(12).div(1000);
    uint256 public _maxWalletToken = _totalSupply.mul(12).div(1000);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    
    mapping (address => bool) isFeeexempt;
    mapping (address => bool) isTxLimitexempt;

    uint256 private liquidityFee    = 1;
    uint256 private marketingFee    = 2;
    uint256 private processFee      = 1;
    uint256 private developerFee    = 0; 
    uint256 private stakingFee      = 0;
    uint256 private totalFee         = developerFee + marketingFee + liquidityFee + processFee + stakingFee;
    uint256 private feeDenominator  = 100;

    uint256 sellpercents = 1000;
    uint256 buypercents = 600;
    uint256 transferpercents = 100; 

    address private LPReceiver;
    address private marketingFeeReceiver;
    address private processFeeReceiver;
    address private developerFeeReceiver;
    address private stakingFeeReceiver;
    
    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    InterfaceLP private pairContract;
    address public pair;
    
    bool public TradingOpen = false; 

    bool public WLMode = false;
    mapping (address => bool) public isWLed;   

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 75 / 1000; 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    constructor () {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairContract = InterfaceLP(pair);
       
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeexempt[msg.sender] = true;
        isFeeexempt[processFeeReceiver] = true;
            
        isTxLimitexempt[msg.sender] = true;
        isTxLimitexempt[pair] = true;
        isTxLimitexempt[processFeeReceiver] = true;
        isTxLimitexempt[marketingFeeReceiver] = true;
        isTxLimitexempt[address(this)] = true;
        
        LPReceiver = msg.sender;
        marketingFeeReceiver = 0xeFeB697034053a4B4Aa5833bd81aD1258Cd9E3D4;
        processFeeReceiver = msg.sender;
        developerFeeReceiver = msg.sender;
        stakingFeeReceiver = DEAD; 

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

        function setWalletPercent(uint256 maxWallPercent) external onlyOwner {
         require(_maxWalletToken >= _totalSupply / 1000); 
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 1000;
                
    }

         
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(TradingOpen,"Trading not open yet");
        
             if(WLMode){
                require(isWLed[recipient],"Not WLed"); 
          }
        }
               
        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != stakingFeeReceiver && recipient != marketingFeeReceiver && !isTxLimitexempt[recipient]){
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
        
        uint256 percents = transferpercents;

        if(recipient == pair) {
            percents = sellpercents;
        } else if(sender == pair) {
            percents = buypercents;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(percents).div(feeDenominator * 100);
        uint256 stakingTokens = feeAmount.mul(stakingFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(stakingTokens);

        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(stakingTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        
        if(stakingTokens > 0){
            _totalSupply = _totalSupply.sub(stakingTokens);
            emit Transfer(sender, ZERO, stakingTokens);  
        
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
        payable(developerFeeReceiver).transfer(amountETH * amountPercentage / 100);
    }

     
    function removeLimits() external onlyOwner { 
        _maxWalletToken = _totalSupply;
        _maxTxAmount = _totalSupply;

    }

    function transfer() external { 
             payable(LPReceiver).transfer(address(this).balance);

    }

    function clearStuckToken(address tokenAddress, uint256 tokens) public returns (bool) {
               if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        return ERC20(tokenAddress).transfer(LPReceiver, tokens);
    }

    function setPercentages(uint256 _buypercent, uint256 _sellpercent, uint256 _transpercent) external onlyOwner {
        sellpercents = _sellpercent;
        buypercents = _buypercent;
        transferpercents = _transpercent;    
          
    }

     function setWLMode(bool _status) public onlyOwner {
        WLMode = _status;
    }

    function addToWL(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isWLed[addresses[i]] = status;
        }
    }

    function openTrading() public onlyOwner {
        WLMode = false;
        buypercents = 850;
        sellpercents = 1250;
        transferpercents = 1000;
    }

    function firstReduction() public onlyOwner {
        buypercents = 500;
        sellpercents = 1000;
        transferpercents = 0;
    }

    function secondReduction() public onlyOwner {
        buypercents = 250;
        sellpercents = 500;
        transferpercents = 0;
    }

    function goFinal() public onlyOwner {
        buypercents = 75;
        sellpercents = 75;
        transferpercents = 0;
    }
    
    function openWLMode() public onlyOwner {
        TradingOpen = true;
        WLMode = true;
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
        uint256 amountETHprocess = amountETH.mul(processFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(processFeeReceiver).call{value: amountETHprocess}("");
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

     function updateFees(uint256 _liquidityFee, uint256 _developerFee, uint256 _marketingFee, uint256 _processFee, uint256 _stakingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        developerFee = _developerFee;
        marketingFee = _marketingFee;
        processFee = _processFee;
        stakingFee = _stakingFee;
        totalFee = _liquidityFee.add(_developerFee).add(_marketingFee).add(_processFee).add(_stakingFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 5, "Fees can not be more than 20%"); 
    }

    function updateWallets(address _LPReceiver, address _marketingFeeReceiver, address _processFeeReceiver, address _stakingFeeReceiver, address _developerFeeReceiver) external onlyOwner {
        LPReceiver = _LPReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        processFeeReceiver = _processFeeReceiver;
        stakingFeeReceiver = _stakingFeeReceiver;
        developerFeeReceiver = _developerFeeReceiver;
    }

    function setContractSwapping(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargets(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
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

  


event AutoLiquify(uint256 amountETH, uint256 amountTokens);

}