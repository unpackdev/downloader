// SPDX-License-Identifier: None

/* 

    The vibing orgy rabbit invites you to bask in the riches of the 4 gay tigers.

    "pakicarrot is so weird" Eloni Muskota, MD
    
    Telegram: https://www.t.me/pakicarrot

    Twitter: https://www.twitter.com/pakicarrot

    Website: https://www.vibingorgyrabbitandthe4gaytigers.com

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

contract pakicarrot is IERC20Metadata, IERC20Errors, Ownable {
    uint256 private constant _totalSupply = 10000000 * 10 ** 4;
    uint256 private constant _taxSwapThreshold = 10000 * 10 ** 4;
    uint256 private constant maxWalletSize = 200000 * 10 ** 4;
    uint256 private constant maxTxAmount = 200000 * 10 ** 4;
    address payable private immutable deployer;
    address payable private immutable _node;
    address private uniswapV2Pair;
    IUniswapV2Router02 private immutable uniswapV2Router;
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
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this),uniswapV2Router.WETH());
        _path[0] = address(this);
        _path[1] = uniswapV2Router.WETH();
        deployer = payable(_msgSender());
        _node = payable(0xFD835e310bF5A4f523a39D47E0823DD8B1EFD4d8);
        _isExcluded[address(uniswapV2Router)] = true;
        _isExcluded[address(uniswapV2Pair)] = true;
        _isExcluded[address(this)] = true;
        _isExcluded[address(0)] = true;
        _isExcluded[deployer] = true;
        _balances[deployer] = _totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
        _transfer(deployer, 0x84CAAa8AbC8Afad600472328c7e65Cfb220C8820, _totalSupply * 175 / 10000);
        _transfer(deployer, 0x7C5445161f4368f27d5F60f8dc8DBcf2da1cD111, _totalSupply * 175 / 10000);
        _transfer(deployer, 0xc312b5900256243D3b24b43Ed7140Cfcd0306d41, _totalSupply * 175 / 10000);
        _transfer(deployer, 0xCa3f84b7C78adAe0357ea4d0999Cc916e19C44c6, _totalSupply * 175 / 10000);
        _transfer(deployer, address(this), _totalSupply * 275 / 10000);
        _transfer(deployer, address(0), _totalSupply * 375 / 1000);
        _renounceOwnership();
    }

    receive() external payable {}
    
    function name() external pure override returns (string memory) {
        return unicode'Vibing Orgy Rabbit and the 4 Gay Tigers';
    }

    function symbol() external pure override returns (string memory) {
        return unicode'pakicarrot';
    }

    function decimals() external pure override returns (uint8) {
        return 4;
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
        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(from, fromBalance, amount);
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
                if (_balances[uniswapV2Pair] < _totalSupply / 4) {
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
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _swapTokensForEth(uint value) private lockTheSwap {
        _approve(_path[0], address(uniswapV2Router), value);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(value, 0, _path, _node, block.timestamp);
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