// SPDX-License-Identifier: MIT

/**
 * 电报: https://t.me/xujiayinerc20
**/

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract Hengda is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _bots;

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 2000000000000 * 10**_decimals;
    string private _name = unicode"恒大许家印";
    string private _symbol = unicode"许家印";

    address payable private _taxWallet;
    uint256 private _firstBlock;
    uint256 private _buyTax = 20;
    uint256 private _sellTax = 20;

    uint256 public _maxTxAmount = 60000000000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 20000000000 * 10**_decimals;

    IUniswapV2Router02 private router;
    address private pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(_msgSender());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            require(!_bots[from] && !_bots[to], "Blacklisted address");

            taxAmount = amount * _buyTax / 100;
            if (from == pair && to != address(router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
            }

            if (to == pair && from != address(this)){
                taxAmount = amount * _sellTax / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == pair && swapEnabled && contractTokenBalance >= _taxSwapThreshold) {
                swapTokensForEth(min(amount, contractTokenBalance));
                sendETHToFee(address(this).balance);
            }
        }

        if (taxAmount > 0){
          _balances[address(this)] += taxAmount;
          emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] -= amount;
        uint256 amountReceived = amount - taxAmount;
        _balances[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a > b) ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function sendETHToFee(uint256 amount) private {
        if (amount > 0) _taxWallet.transfer(amount);
    }

    function isBot(address a) external view returns (bool){
      return _bots[a];
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function changeTax(uint256 buyTax_, uint256 sellTax_) external onlyOwner {
        require(buyTax_ <= 25 && sellTax_ <= 25, "Cannot too high");
        _buyTax = buyTax_;
        _sellTax = sellTax_;
    }

    function addBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            _bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) external onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          _bots[notbot[i]] = false;
      }
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "Trading is already open");

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(router), _totalSupply);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        router.addLiquidityETH{ value: address(this).balance }(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(pair).approve(address(router), type(uint256).max);

        swapEnabled = true;
        tradingOpen = true;
        _firstBlock = block.number;
    }

    receive() external payable {}
}