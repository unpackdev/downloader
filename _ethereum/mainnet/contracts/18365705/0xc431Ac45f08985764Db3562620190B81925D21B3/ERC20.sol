// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Twitter: https://twitter.com/0xBased290415
// Website: https://0xbased.io/
// Docs: https://docs.0xbased.io/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router {
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

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsOut(
        uint256 amountIn, 
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external view returns (uint[] memory amounts);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address public owner;
    address private vesting;
    uint256 private claim_count_1 = 0;
    uint256 private claim_count_2 = 0;
    uint256 private deploy_timestamp;
    uint256 private vesting_period = 30*24*60*60*2; //seconds
    uint256 private vesting_balance;
    uint256 private claim_amount;
    address private marketing_1 = 0x544FdE36ED7991F91510B0Ab96A449cC09a63EAb;
    address private marketing_2 = 0xEd26FCc338c79587b727C8dd84b1623924B7420e;
    uint256 private _totalSupply;
    string  private _name;
    string  private _symbol;
    uint256 public buy_fee  = 250;
    uint256 public sell_fee = 300;  

    uint256 public maxBuySell; 
    uint256 private swapThreshold = 0;

    bool public inSwapAndLiquify = false;
    bool public feeSwapEnable = false;

    address private constant RouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;      
    address private constant WrappedNativeToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  

    function getPoolAddress() public view returns (address) {        
        address poolAddress = IUniswapV2Factory(IUniswapV2Router(RouterV2).factory()).getPair(address(this), WrappedNativeToken);        
        return poolAddress;
    }
    function getAmountOutMin(uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = address(this);
		path[1] = IUniswapV2Router(RouterV2).WETH();
		uint256[] memory amountOutMins = IUniswapV2Router(RouterV2).getAmountsOut(_amount, path);
		return amountOutMins[path.length - 1];
	}   
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    function swapTokensForETH() public  {
        IERC20(address(this)).approve(RouterV2, type(uint256).max);
        uint256 tokenBalance = balanceOf(address(this)) - vesting_balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(RouterV2).WETH();
        IUniswapV2Router(RouterV2).swapExactTokensForETH(
            tokenBalance,
            1,
            path,
            address(this),
            block.timestamp
        );
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function claim_1() public {
        require(marketing_1 == msg.sender, "Ownable: caller is not the vesting");
        require((block.timestamp - deploy_timestamp) / vesting_period > claim_count_1 , "You can't brand that much in this vesting period");
        require(4 > claim_count_1 , "Vesting for this wallet is closed");
        vesting_balance - claim_amount;
        IERC20(address(this)).transfer(marketing_1, claim_amount);
        claim_count_1++;
    }
    function claim_2() public {
        require(marketing_2 == msg.sender, "Ownable: caller is not the vesting");
        require((block.timestamp - deploy_timestamp) / vesting_period > claim_count_2 , "You can't brand that much in this vesting period");
        require(4 > claim_count_2 , "Vesting for this wallet is closed");
        vesting_balance - claim_amount;
        IERC20(address(this)).transfer(marketing_2, claim_amount);
        claim_count_2++;
    }
    function setFees_15_20() public onlyOwner {                
        buy_fee  = 150;  
        sell_fee = 200;  
    }
    function setFees_10_10() public onlyOwner {                
        buy_fee  = 100;
        sell_fee = 100;
    }
    function setFees__0_8__1_2() public onlyOwner {                
        buy_fee  = 8;
        sell_fee = 12; 
    }
    function removeAllFees() public onlyOwner {
        buy_fee  = 0;
        sell_fee = 0; 
    }
    function RemoveAllLimits() public onlyOwner {
       maxBuySell = 0;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function exclude_from_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }    
    function include_in_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }  

    constructor() {
        _name = "0xbased";
        _symbol = "0xb";
        
        uint256 owner_balance = 92000000*10**5;
        vesting_balance = 8000000*10**5;    
        claim_amount = vesting_balance / 8;
        _balances[msg.sender] = owner_balance;
        _balances[address(this)] = vesting_balance;
        emit Transfer(address(0), msg.sender, owner_balance);
        emit Transfer(address(0), address(this), vesting_balance);
       
        _totalSupply = vesting_balance + owner_balance;
        maxBuySell =  _totalSupply * 2 / 100;
        owner = msg.sender;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[marketing_1] = true;
        _isExcludedFromFee[marketing_2] = true;
        _isExcludedFromFee[address(this)] = true;
        deploy_timestamp = block.timestamp;

        // create pool
        IUniswapV2Factory(IUniswapV2Router(RouterV2).factory()).createPair(address(this), WrappedNativeToken);       
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    } 
    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);
        return true;
    }
    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, allowance(_owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address _owner = _msgSender();
        uint256 currentAllowance = allowance(_owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");      
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        //swap fees
        if (feeSwapEnable){
            uint256 AmountOutMin = getAmountOutMin(_balances[address(this)] - vesting_balance);                
            if(AmountOutMin > swapThreshold &&  !inSwapAndLiquify &&  from != getPoolAddress()){
                inSwapAndLiquify = true;
                swapTokensForETH();
                inSwapAndLiquify = false;    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwapAndLiquify) {           
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;        
            emit Transfer(from, to, amount);
        } else {             
                if (to == getPoolAddress() || from == getPoolAddress()) {
                    uint256 _this_fee;   
                    if(maxBuySell > 0) require(maxBuySell >= amount, "ERC20: The amount of the transfer is more than allowed");
                    if(to == getPoolAddress()) _this_fee = sell_fee; //if sell 
                    if(from == getPoolAddress()) _this_fee = buy_fee; //if buy                    
                
                    uint256 _amount = amount * (1000 - _this_fee) / 1000;
                    _balances[from] = fromBalance - amount;
                    _balances[to]   += _amount;
                    emit Transfer(from, to, _amount);
            
                    uint256 _this_fee_value  = amount * _this_fee  / 1000;               
                    _balances[address(this)] += _this_fee_value;                   
                } else { //if transfer             
                    _balances[from] = fromBalance - amount;
                    _balances[to] += amount;               
                    emit Transfer(from, to, amount);
                } 
            }
         // send fees   
         if(address(this).balance > 1 ){
            uint256 send_balance = address(this).balance / 2;
            payable(marketing_1).transfer(send_balance);
            payable(marketing_2).transfer(send_balance);
         }    
    }
    function set_swapThresholdx(uint256 _swapThreshold) public onlyOwner {
        swapThreshold = _swapThreshold;
    }
    function flipFeeSwapEnable() public onlyOwner {
        feeSwapEnable = !feeSwapEnable;
    }
    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function _spendAllowance(address _owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
    receive() external payable {}
}