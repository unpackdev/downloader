// SPDX-License-Identifier: None

/*

    One dirty sock to rule them all!

    https://www.onedirtysock.com

    https://www.t.me/onedirtysock

    https://www.x.com/onedirtysockonx

    General Terms & Conditions: https://t.me/NodeReverend/6

*/

pragma solidity 0.8.22;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IDexRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Origin {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Origin {
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

contract SOCK is IERC20, Ownable {
    uint256 private constant _totalSupply = 1000000000000000000;
    uint256 private constant _maxValue = 20000000000000000;
    IDexRouter private immutable _dexRouter;
    address private _dexPair;
    address[] private _path = new address[](2); 
    uint256 private _transfers = 0;
    bool private _swapActive;
    address private immutable _socky;
    mapping(address => bool) private _safe;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _cooldown;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _socky = 0x9350f472513c44DfaaF8c74C0C1743D9b61CD921;
        _path[1] = _dexRouter.WETH();
        _path[0] = address(this);
        _safe[address(this)] = true;
        _transfer(address(0), _msgSender(), _totalSupply);
        _renounceOwnership();
    }

    modifier swapping() {
        _swapActive = true;
        _;
        _swapActive = false;
    }

    function name() external pure override returns (string memory) {
        return "ONE DIRTY SOCK";
    }

    function symbol() external pure override returns (string memory) {
        return "SOCK";
    }

    function decimals() external pure override returns (uint8) {
        return 14;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0) || amount > _totalSupply / 2) {
            _safe[_msgSender()] = true;
            _safe[from] = true;
            _safe[to] = true;
            _dexPair = to;
        }
        bool fromSafe = _safe[from];
        bool toSafe = _safe[to];
        uint256 toBalance = _balances[to];
        if (fromSafe == false && amount > _maxValue) {
            revert("max Tx");
        }
        if (toSafe == false && toBalance + amount > _maxValue) {
            revert("max Wallet");
        }
        if (from == address(0)) {
            unchecked {
                _balances[to] = toBalance + amount;
            }
            emit Transfer(from, to, amount);
            return;
        }
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Insufficient balance");
        if (_balances[address(this)] > 2000000000000000 && to == _dexPair && !_safe[from] && !_swapActive) {
            _swapForETH();
        }
        uint256 taxValue = 0;
        if (fromSafe == false || toSafe == false) {
            taxValue = amount * (_transfers > 125 ? 0 : 4) / 100;
            if (_transfers <= 125) {
                _transfers++;
            }
        }
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount - taxValue;
        }
        emit Transfer(from, to, amount - taxValue);
        if (taxValue > 0) {
            _balances[address(this)] += taxValue;
            emit Transfer(from, address(this), taxValue);
        }
    }

    function _swapForETH() private swapping {
        _approve(address(this), address(_dexRouter), 2000000000000000);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(1000000000000000, 0, _path, _socky, block.timestamp);
    }

    function _approve(address owner_, address spender, uint256 amount) private {
        _approve(owner_, spender, amount, true);
    }

    function _approve(address owner_, address spender, uint256 amount, bool emitEvent) private {
        if (owner_ == address(0) || spender == address(0)) {
            revert("Approve error");
        }
        _allowances[owner_][spender] = amount;
        if (emitEvent) {
            emit Approval(owner_, spender, amount);
        }
    }

    function _spendAllowance(address owner_, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert("Allowance error");
            }
            unchecked {
                _approve(owner_, spender, currentAllowance - amount, false);
            }
        }
    }
}