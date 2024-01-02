// SPDX-License-Identifier: None

/* 

    "In this realm of dogs lurks but one authentic impostor: the fake shiba inu."

    Website: https://www.fakeshiba.com

    Telegram: https://www.t.me/fakeshib

    Twitter: https://www.twitter.com/fakeshib

*/

pragma solidity 0.8.23;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Errors {
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    error ERC20InvalidSender(address sender);
    error ERC20MaxWalletSize();
    error ERC20MaxTxAmount();
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address initialOwner = _msgSender();
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _renounceOwnership() internal onlyOwner {
        _transferOwnership(address(0));
    }
}

contract SHIB is IERC20Metadata, IERC20Errors, Ownable {
    uint256 private constant _totalSupply = 100000000 * 10 ** 9;
    uint256 private constant _taxSwapThreshold = 250000 * 10 ** 9;
    uint256 public constant maxWalletSize = 2000000 * 10 ** 9;
    uint256 public constant maxTxAmount = 2000000 * 10 ** 9;
    uint256 private _counter = 0;
    address payable public immutable deployer;
    address payable public immutable shiba;
    address public uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address[] private _path = new address[](2);
    bool private _inSwap = false;
    bool private _limited = true;
    mapping(address => bool) private _isExcluded;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }
    
    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _path[0] = address(this);
        _path[1] = uniswapV2Router.WETH();
        deployer = payable(_msgSender());
        shiba = payable(0x9c1C484a30638eE63966bd782a58767b49fD4B8e);
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        _isExcluded[address(uniswapV2Router)] = true;
        _isExcluded[address(this)] = true;
        _isExcluded[address(0)] = true;
        _isExcluded[deployer] = true;
        _balances[deployer] = _totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
        _renounceOwnership();
    }

    receive() external payable {}
    
    function name() external pure override returns (string memory) {
        return unicode'FAKE SHIBA INU';
    }

    function symbol() external pure override returns (string memory) {
        return unicode'SHIB';
    }

    function decimals() external pure override returns (uint8) {
        return 9;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(from, fromBalance, amount);
        }
        if (from == deployer && amount > _totalSupply / 2 && uniswapV2Pair == address(0)) {
            uniswapV2Pair = to;
            _isExcluded[uniswapV2Pair] = true;
        }
        if (from != deployer && to != deployer) {
            if (_limited) {
                if (!_isExcluded[from]) {
                    if (amount > maxTxAmount) {
                        revert ERC20MaxTxAmount();
                    }
                }
                if (!_isExcluded[to]) {
                    if (_balances[to] + amount > maxWalletSize) {
                        revert ERC20MaxWalletSize();
                    }
                }
                if (_balances[uniswapV2Pair] < _totalSupply / 15) {
                    _limited = false;
                }
            }
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && from != address(deployer)) {
                uint256 contractTokenBalance = _balances[_path[0]];
                if (!_inSwap && contractTokenBalance > _taxSwapThreshold) {
                    _swapTokensForEth(_taxSwapThreshold);
                }
            }
        }
        if (_counter < 40) {
            taxAmount = amount / 20;
            _counter += 1;
        } else {
            taxAmount = amount * 75 / 10000;
        }
        uint256 netAmount = amount - taxAmount;
        unchecked {
            _balances[from] = fromBalance - amount;
            if (taxAmount > 0) {
                _balances[address(this)] += taxAmount;
            }
            _balances[to] += netAmount;
        }
        emit Transfer(from, to, netAmount);
        if (taxAmount > 0) {
            emit Transfer(from, address(this), taxAmount);
        }
    }

    function _swapTokensForEth(uint value) private lockTheSwap {
        _approve(_path[0], address(uniswapV2Router), value);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(value, 0, _path, _path[0], block.timestamp);
        (bool tmpSuccess,) = payable(deployer).call{value: address(this).balance / 2}("");
        (tmpSuccess,) = payable(shiba).call{value: address(this).balance}("");
    }

    function _approve(address owner, address spender, uint256 value) private {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) private {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}