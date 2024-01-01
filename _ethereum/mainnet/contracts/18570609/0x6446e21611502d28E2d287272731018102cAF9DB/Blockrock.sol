// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.23;

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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Blockrock is Context, IERC20, Ownable {
    uint256 private constant _totalSupply = 10_000_000e18;
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address immutable uniswapV2Pair;
    address immutable WETH;
    address payable immutable marketingWallet;

    uint8 private launch;
    uint8 private inSwapAndLiquify;

    uint256 private launchBlock;
    uint256 public maxTxAmount = 100_000e18;

    string private constant _name = unicode"Blockrock";
    string private constant _symbol = unicode"FED";

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private initialTax = 50; 
    uint256 private decrementAmount = 2; 
    uint256 private decrementInterval = 5;
    uint256 private fnBuyTax = 4; 
    uint256 private fnSellTax = 6; 

    constructor() {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        marketingWallet = payable(0x55DC8eAc6391cBc6358f3EF40Ea6fED7341A6cfB);
        _balances[msg.sender] = _totalSupply;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;

                _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;
        _allowances[marketingWallet][address(uniswapV2Router)] = type(uint256).max;

        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function toggleTrading() external onlyOwner {
        launch = 1;
        launchBlock = block.number;
    }

    function addExcludedWallet(address wallet) external onlyOwner {
        _isExcludedFromFee[wallet] = true;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 tax = 0;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            tax = currentFederal(from, to, amount);
        }

        uint256 transferAmount = amount - tax;
        _balances[from] -= amount;
        _balances[to] += transferAmount;
        if (tax > 0) {
            _balances[address(this)] += tax;
            emit Transfer(from, address(this), tax);
        }
        emit Transfer(from, to, transferAmount);
    }

    function currentFederal(address from, address to, uint256 amount) private view returns (uint256 tax) {
        uint256 currentTaxRate;
        if (from == uniswapV2Pair) {
            // Buy transaction
            currentTaxRate = FederalEarlyTax(true);
        } else if (to == uniswapV2Pair) {
            // Sell transaction
            currentTaxRate = FederalEarlyTax(false);
        }

        tax = (amount * currentTaxRate) / 100;
}

    function FederalEarlyTax(bool isBuy) private view returns (uint256) {
        uint256 stepsSinceLaunch = (block.number - launchBlock) / decrementInterval;
        uint256 decreaseAmount = stepsSinceLaunch * decrementAmount;
        uint256 currentTax;

        if (isBuy) {
            currentTax = initialTax > decreaseAmount ? initialTax - decreaseAmount : fnBuyTax;
            return currentTax < fnBuyTax ? fnBuyTax : currentTax;
        } else {
            currentTax = initialTax > decreaseAmount ? initialTax - decreaseAmount : fnSellTax;
            return currentTax < fnSellTax ? fnSellTax : currentTax;
        }
    }

    receive() external payable {}
}