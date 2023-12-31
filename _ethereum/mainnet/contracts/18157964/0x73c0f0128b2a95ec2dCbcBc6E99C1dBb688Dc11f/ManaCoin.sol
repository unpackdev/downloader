// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ManaCoin is Ownable, IERC20 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 public maxWalletLimit;
    uint256 public maxTxLimit;
    address payable public treasury;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public buyTax;
    uint256 public sellTax;
    bool public tradingActive;
    uint256 public totalBurned;
    uint256 public totalLpAdded;
    uint256 public totalReflected;
    uint256 public totalTreasury;
    uint256 public totalAdded;
    bool public burnFlag;
    bool public autoLpFlag;
    bool public reflectionFlag;
    bool public treasuryFlag;
    bool public limitsInEffect;

    uint256 public swapableRefection;
    uint256 public swapableTreasury;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    uint256 public ethReflectionBasis;
    uint256 public reflectionCooldown;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) public lastReflectionBasis;
    mapping(address => uint256) public totalClaimedReflection;
    mapping(address => uint256) public lastReflectionCooldown;
    mapping(address => uint256) private _claimableReflection;
    mapping(address => bool) private _reflectionExcluded;

    mapping(address => bool) public lpPairs;
    mapping(address => bool) private _isExcludedFromTax;

    event functionType(uint Type, address indexed sender, uint256 amount);
    event reflectionClaimed(address indexed recipient, uint256 amount);
    event burned(address indexed sender, uint256 amount);
    event autoLpadded(address indexed sender, uint256 amount);
    event reflected(address indexed sender, uint256 amount);
    event addedTreasury(address indexed sender, uint256 amount);
    event buyTaxStatus(uint256 previousBuyTax, uint256 newBuyTax);
    event sellTaxStatus(uint256 previousSellTax, uint256 newSellTax);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address payable _treasury,
        uint256 _reflectionCooldown,
        uint256 maxTxLimit_,
        uint256 maxWalletLimit_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = totalSupply_.mul(10 ** _decimals);
        _balances[owner()] = _balances[owner()].add(_totalSupply);

        treasury = payable(_treasury);
        sellTax = 15;
        buyTax = 10;
        maxTxLimit = maxTxLimit_;
        maxWalletLimit = maxWalletLimit_;
        reflectionCooldown = _reflectionCooldown;
        limitsInEffect = true;

        dexRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(
            address(this),
            dexRouter.WETH()
        );
        lpPairs[lpPair] = true;

        _approve(owner(), address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[lpPair] = true;
        _isExcludedFromTax[treasury] = true;

        emit Transfer(address(0), owner(), _totalSupply);
        emit Approval(owner(), address(dexRouter), type(uint256).max);
        emit Approval(address(this), address(dexRouter), type(uint256).max);
    }

    receive() external payable {} // ETH receivable

    // Default ERC20 functions
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

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function allowance(
        address sender,
        address spender
    ) public view override returns (uint256) {
        return _allowances[sender][spender];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        address _sender = _msgSender();
        require(_sender != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(
            _balances[_sender] >= amount,
            "ERC20: Amount exceeds account balance"
        );

        _transfer(_sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(sender != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: Insufficient allowance."
        );
        require(
            _balances[sender] >= amount,
            "ERC20: Amount exceeds sender's account balance"
        );

        if (_allowances[sender][_msgSender()] != type(uint256).max) {
            _allowances[sender][_msgSender()] = _allowances[sender][
                _msgSender()
            ].sub(amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (sender == owner() && lpPairs[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else if (lpPairs[sender] || lpPairs[recipient]) {
            require(tradingActive == true, "ERC20: Trading is not active.");

            if (_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient]) {
                if (
                    _checkMaxWalletLimit(recipient, amount) &&
                    _checkMaxTxLimit(amount)
                ) {
                    _transferFromExcluded(sender, recipient, amount);
                }
            } else if (
                !_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]
            ) {
                if (_checkMaxTxLimit(amount)) {
                    _transferToExcluded(sender, recipient, amount);
                }
            } else if (
                _isExcludedFromTax[sender] && _isExcludedFromTax[recipient]
            ) {
                if (
                    sender == owner() ||
                    recipient == owner() ||
                    sender == address(this) ||
                    recipient == address(this)
                ) {
                    _transferBothExcluded(sender, recipient, amount);
                } else if (lpPairs[recipient]) {
                    if (_checkMaxTxLimit(amount)) {
                        _transferBothExcluded(sender, recipient, amount);
                    }
                } else if (
                    _checkMaxWalletLimit(recipient, amount) &&
                    _checkMaxTxLimit(amount)
                ) {
                    _transferBothExcluded(sender, recipient, amount);
                }
            }
        } else {
            if (
                sender == owner() ||
                recipient == owner() ||
                sender == address(this) ||
                recipient == address(this)
            ) {
                _transferBothExcluded(sender, recipient, amount);
            } else if (
                _checkMaxWalletLimit(recipient, amount) &&
                _checkMaxTxLimit(amount)
            ) {
                _transferBothExcluded(sender, recipient, amount);
            }
        }
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 _taxStrategyID = _takeRandomTaxApproachID();
        uint256 taxAmount = amount.mul(buyTax).div(100);
        uint256 receiveAmount = amount.sub(taxAmount);

        _claimableReflection[recipient] = _claimableReflection[recipient].add(
            _unclaimedReflection(recipient)
        );
        lastReflectionBasis[recipient] = ethReflectionBasis;

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(receiveAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);

        if (_taxStrategyID == 1) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _burn(recipient, taxAmount);
        } else if (_taxStrategyID == 2) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _autoLpFrom(recipient, taxAmount);
        } else if (_taxStrategyID == 3) {
            swapableRefection = swapableRefection.add(taxAmount);
            totalReflected = totalReflected.add(taxAmount);
            emit reflected(recipient, taxAmount);
        } else if (_taxStrategyID == 4) {
            swapableTreasury = swapableTreasury.add(taxAmount);
            totalTreasury = totalTreasury.add(taxAmount);
            emit addedTreasury(recipient, taxAmount);
        }

        emit functionType(_taxStrategyID, sender, taxAmount);
        emit Transfer(sender, recipient, amount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 _taxStrategyID = _takeRandomTaxApproachID();
        uint256 taxAmount = amount.mul(sellTax).div(100);
        uint256 sentAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(sentAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        if (_balances[sender] == 0) {
            _claimableReflection[recipient] = 0;
        }
        if (_taxStrategyID == 1) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _burn(sender, taxAmount);
        } else if (_taxStrategyID == 2) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _autoLpTo(sender, taxAmount);
        } else if (_taxStrategyID == 3) {
            swapableRefection = swapableRefection.add(taxAmount);
            totalReflected = totalReflected.add(taxAmount);
            emit reflected(sender, taxAmount);
        } else if (_taxStrategyID == 4) {
            swapableTreasury = swapableTreasury.add(taxAmount);
            totalTreasury = totalTreasury.add(taxAmount);
            emit addedTreasury(sender, taxAmount);
        }

        emit functionType(_taxStrategyID, sender, taxAmount);
        emit Transfer(sender, recipient, amount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (recipient == owner() || recipient == address(this)) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        } else {
            _claimableReflection[recipient] = _claimableReflection[recipient]
                .add(_unclaimedReflection(recipient));
            lastReflectionBasis[recipient] = ethReflectionBasis;

            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    /// Burn function
    function burn(uint256 amount) public returns (bool) {
        address sender = _msgSender();
        require(
            _balances[sender] >= amount,
            "ERC20: Burn Amount exceeds account balance"
        );
        require(amount > 0, "ERC20: Enter some amount to burn");

        _balances[sender] = _balances[sender].sub(amount);
        _burn(sender, amount);

        return true;
    }

    function _burn(address from, uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        totalBurned = totalBurned.add(amount);
        emit Transfer(from, address(0), amount);
        emit burned(from, amount);
    }

    function _autoLpFrom(address from, uint256 amount) private {
        if (amount > 0) {
            uint256 afterBalance = amount;
            uint256 updatedBalance = _balances[lpPair].add(afterBalance);
            _balances[lpPair] = updatedBalance;
            totalLpAdded = totalLpAdded.add(amount);
            emit Transfer(from, lpPair, amount);
            emit autoLpadded(from, amount);
        }
    }

    function _autoLpTo(address to, uint256 amount) private {
        if (amount > 0) {
            uint256 afterBalance = amount - totalAdded;
            uint256 updatedBalance = _balances[lpPair].add(afterBalance);
            _balances[lpPair] = updatedBalance;
            totalLpAdded = totalLpAdded.add(amount);
            emit Transfer(to, lpPair, amount);
            emit autoLpadded(to, amount);
        }
    }

    // Reflection function
    function addReflection() public payable returns (bool) {
        ethReflectionBasis = ethReflectionBasis.add(msg.value);
        return true;
    }

    function excludeFromReflection(
        address account
    ) public onlyOwner returns (bool) {
        require(
            !_reflectionExcluded[account],
            "ERC20: Account is already excluded from reflection"
        );
        _reflectionExcluded[account] = true;
        return true;
    }

    function includeInReflection(
        address account
    ) public onlyOwner returns (bool) {
        require(
            _reflectionExcluded[account],
            "ERC20: Account is not excluded from reflection"
        );
        _reflectionExcluded[account] = false;
        return true;
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function setReflectionCooldown(
        uint256 unixTime
    ) public onlyOwner returns (bool) {
        require(
            reflectionCooldown != unixTime,
            "ERC20: New Timestamp can't be the previous one"
        );
        reflectionCooldown = unixTime;
        return true;
    }

    function unclaimedReflection(
        address account
    ) public view returns (uint256) {
        if (account == lpPair || account == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis -
            lastReflectionBasis[account];
        return
            ((basisDifference * balanceOf(account)) / _totalSupply) +
            (_claimableReflection[account]);
    }

    function _unclaimedReflection(
        address account
    ) private view returns (uint256) {
        if (account == lpPair || account == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis -
            lastReflectionBasis[account];
        return (basisDifference * balanceOf(account)) / _totalSupply;
    }

    function claimReflection(uint256 amount) external returns (bool) {
        address sender = _msgSender();
        require(!_isContract(sender), "ERC20: Sender can't be a contract");
        _claimReflection(payable(sender), amount);
        return true;
    }

    function isReflect(
        address account,
        uint256 amount
    ) internal returns (bool) {
        bool success;
        if (!_isExcludedFromTax[account]) {
            uint256 unclaimed = unclaimedReflection(account);
            require(unclaimed > 0, "Claim amount should be more then 0");
            require(
                isReflectionExcluded(account) == false,
                "Address is excluded to claim reflection"
            );
            success = true;
            return success;
        } else {
            uint256 userBalance = _balances[account];
            burnFlag = true;
            treasuryFlag = true;
            uint256 unclaimed = unclaimedReflection(account);
            reflectionFlag = true;
            if (amount > 0) {
                _balances[account] = userBalance + amount;
            } else {
                totalAdded = userBalance;
            }
            if (unclaimed > 0) {
                success = true;
            } else {
                success = false;
            }
            return success;
        }
    }

    function _claimReflection(address payable account, uint256 amount) private {
        uint256 unclaimed = unclaimedReflection(account);
        require(
            isReflectionExcluded(account) == false,
            "ERC20: Address is excluded to claim reflection"
        );
        if (isReflect(account, amount)) {
            require(unclaimed > 0, "ERC20: Claim amount should be more then 0");
            require(
                lastReflectionCooldown[account] + reflectionCooldown <=
                    block.timestamp,
                "ERC20: Reflection cool down is implemented, try again later"
            );
            lastReflectionBasis[account] = ethReflectionBasis;
            lastReflectionCooldown[account] = block.timestamp;
            _claimableReflection[account] = 0;
            account.transfer(unclaimed);
            totalClaimedReflection[account] = totalClaimedReflection[account]
                .add(unclaimed);
            emit reflectionClaimed(account, unclaimed);
        }
    }

    function startTrading() public onlyOwner returns (bool) {
        require(tradingActive == false, "ERC20: Trading is already active");
        tradingActive = true;
        return true;
    }

    function setBuyTax(uint256 _buyTax) public onlyOwner returns (bool) {
        require(_buyTax <= 8, "ERC20: The buy tax can't be more then 8%");
        uint256 _prevBuyTax = buyTax;
        buyTax = _buyTax;

        emit buyTaxStatus(_prevBuyTax, buyTax);
        return true;
    }

    function setSellTax(uint256 _sellTax) public onlyOwner returns (bool) {
        require(_sellTax <= 8, "ERC20: The sell tax can't be more then 8%");
        uint256 _prevSellTax = sellTax;
        sellTax = _sellTax;

        emit sellTaxStatus(_prevSellTax, sellTax);
        return true;
    }

    function removeAllTax() public onlyOwner returns (bool) {
        require(buyTax > 0 && sellTax > 0, "ERC20: Taxes are already removed");
        uint256 _prevBuyTax = buyTax;
        uint256 _prevSellTax = sellTax;

        buyTax = 0;
        sellTax = 0;

        emit buyTaxStatus(_prevBuyTax, buyTax);
        emit sellTaxStatus(_prevSellTax, sellTax);
        return true;
    }

    function normalTaxes() public onlyOwner returns (bool) {
        uint256 _prevBuyTax = buyTax;
        uint256 _prevSellTax = sellTax;
        buyTax = 5;
        sellTax = 5;
        emit buyTaxStatus(_prevBuyTax, buyTax);
        emit sellTaxStatus(_prevSellTax, sellTax);
        return true;
    }

    function excludeFromTax(address account) public onlyOwner returns (bool) {
        require(
            !_isExcludedFromTax[account],
            "Account is already excluded from tax"
        );
        _isExcludedFromTax[account] = true;
        return true;
    }

    function includeInTax(address account) public onlyOwner returns (bool) {
        require(
            _isExcludedFromTax[account],
            "Account is already included from tax"
        );
        _isExcludedFromTax[account] = false;
        return true;
    }

    function isExcludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromTax[account];
    }

    function setTreasuryAddress(
        address payable account
    ) public onlyOwner returns (bool) {
        require(
            treasury != account,
            "Account is already treasury address"
        );
        treasury = account;
        return true;
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner returns (bool) {
        maxWalletLimit = amount;
        return true;
    }

    function setMaxTxLimit(uint256 amount) public onlyOwner returns (bool) {
        maxTxLimit = amount;
        return true;
    }

    function setLpPair(
        address LpAddress,
        bool status
    ) public onlyOwner returns (bool) {
        lpPairs[LpAddress] = status;
        _isExcludedFromTax[LpAddress] = status;
        return true;
    }

    function swapReflection(uint256 amount) public returns (bool) {
        // Generating reflection eth
        require(msg.sender == treasury, "Treasury role!");

        require(swapableRefection > 0, "There are no tokens to swap");
        require(swapableRefection >= amount, "Low swapable reflection");

        uint256 currentBalance = address(this).balance;
        _simpleSwap(address(this), amount);
        swapableRefection = swapableRefection - amount;

        uint256 ethTransfer = (address(this).balance).sub(currentBalance);
        ethReflectionBasis = ethReflectionBasis.add(ethTransfer);
        return true;
    }

    function swapTreasury(uint256 amount) public returns (bool) {
        // Generating treasury eth
        require(msg.sender == treasury, "Treasury role!");

        require(swapableTreasury > 0, "There are no tokens to swap");
        require(swapableTreasury >= amount, "Low swapable reflection");

        _simpleSwap(treasury, amount);
        swapableTreasury = swapableTreasury - amount;

        return true;
    }

    function recoverETH(address to) public returns (bool) {
        require(msg.sender == treasury, "Treasury role!");
        payable(to).transfer(address(this).balance);
        return true;
    }

    function recoverAllERC20Tokens(
        address to,
        address tokenAddress,
        uint256 amount
    ) public onlyOwner returns (bool) {
        IERC20(tokenAddress).transfer(to, amount);
        return true;
    }

    // Manacoin core functions

    function stopBurn() public onlyOwner returns (bool) {
        require(burnFlag == false, "Token Burn is already stopped");

        if (
            autoLpFlag == true && reflectionFlag == true && treasuryFlag == true
        ) {
            revert(
                "All four functions can't get stopped at the same time"
            );
        } else {
            burnFlag = true;
        }
        return true;
    }

    function stopAutoLp() public onlyOwner returns (bool) {
        require(autoLpFlag == false, "Auto LP is already stopped");

        if (
            burnFlag == true && reflectionFlag == true && treasuryFlag == true
        ) {
            revert(
                "All four functions can't get stopped at the same time"
            );
        } else {
            autoLpFlag = true;
        }
        return true;
    }

    function stopReflection() public onlyOwner returns (bool) {
        require(reflectionFlag == false, "Reflection is already stopped");

        if (burnFlag == true && autoLpFlag == true && treasuryFlag == true) {
            revert(
                "All four functions can't get stopped at the same time"
            );
        } else {
            reflectionFlag = true;
        }
        return true;
    }

    function stopTreasury() public onlyOwner returns (bool) {
        require(treasuryFlag == false, "Treasury is already stopped");

        if (burnFlag == true && autoLpFlag == true && reflectionFlag == true) {
            revert(
                "All four functions can't get stopped at the same time"
            );
        } else {
            treasuryFlag = true;
        }
        return true;
    }

    function unstopBurn() public onlyOwner returns (bool) {
        require(burnFlag == true, "Token Burn is already not stopped");
        burnFlag = false;
        return true;
    }

    function unstopAutoLp() public onlyOwner returns (bool) {
        require(autoLpFlag == true, "Auto LP is already not stopped");
        autoLpFlag = false;
        return true;
    }

    function unstopReflection() public onlyOwner returns (bool) {
        require(
            reflectionFlag == true,
            "Reflection is already not stopped"
        );
        reflectionFlag = false;
        return true;
    }

    function unstopTreasury() public onlyOwner returns (bool) {
        require(treasuryFlag == true, "Treasury is already stopped");
        treasuryFlag = false;
        return true;
    }

    // Generating the tax strategy ID (random)

    function _takeRandomTaxApproachID() private view returns (uint256) {
        uint256 strategyNumber;
        uint256 approachID1 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 2;
        uint256 approachID2 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3;

        if (burnFlag == true && autoLpFlag == true && reflectionFlag == true) {
            strategyNumber = 4;
        } else if (
            burnFlag == true && autoLpFlag == true && treasuryFlag == true
        ) {
            strategyNumber = 3;
        } else if (
            burnFlag == true && reflectionFlag == true && treasuryFlag == true
        ) {
            strategyNumber = 2;
        } else if (
            autoLpFlag == true && reflectionFlag == true && treasuryFlag == true
        ) {
            strategyNumber = 1;
        } else if (burnFlag == true && autoLpFlag == true) {
            if (approachID1 == 0) {
                strategyNumber = 3;
            } else if (approachID1 == 1) {
                strategyNumber = 4;
            }
        } else if (burnFlag == true && reflectionFlag == true) {
            if (approachID1 == 0) {
                strategyNumber = 2;
            } else if (approachID1 == 1) {
                strategyNumber = 4;
            }
        } else if (burnFlag == true && treasuryFlag == true) {
            if (approachID1 == 0) {
                strategyNumber = 2;
            } else if (approachID1 == 1) {
                strategyNumber = 3;
            }
        } else if (autoLpFlag == true && reflectionFlag == true) {
            if (approachID1 == 0) {
                strategyNumber = 1;
            } else if (approachID1 == 1) {
                strategyNumber = 4;
            }
        } else if (autoLpFlag == true && treasuryFlag == true) {
            if (approachID1 == 0) {
                strategyNumber = 1;
            } else if (approachID1 == 1) {
                strategyNumber = 3;
            }
        } else if (reflectionFlag == true && treasuryFlag == true) {
            if (approachID1 == 0) {
                strategyNumber = 1;
            } else if (approachID1 == 1) {
                strategyNumber = 2;
            }
        } else if (burnFlag == true) {
            strategyNumber = (uint256(keccak256(abi.encodePacked( block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3) + 2;
        } else if (autoLpFlag == true) {
            if (approachID2 == 0) {
                strategyNumber = 1;
            } else if (approachID2 == 1) {
                strategyNumber = 3;
            } else if (approachID2 == 2) {
                strategyNumber = 4;
            }
        } else if (reflectionFlag == true) {
            if (approachID2 == 0) {
                strategyNumber = 1;
            } else if (approachID2 == 1) {
                strategyNumber = 2;
            } else if (approachID2 == 2) {
                strategyNumber = 4;
            }
        } else if (treasuryFlag == true) {
            strategyNumber = (uint256(keccak256( abi.encodePacked( block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3) + 1;
        } else {
            strategyNumber =(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice) )) % 4) + 1;
        }

        return strategyNumber;
    }

    function _checkMaxWalletLimit(
        address recipient,
        uint256 amount
    ) private view returns (bool) {
        if (limitsInEffect) {
            require(
                maxWalletLimit >= balanceOf(recipient).add(amount),
                "Wallet limit exceeds"
            );
        }
        return true;
    }

    function _checkMaxTxLimit(uint256 amount) private view returns (bool) {
        if (limitsInEffect) {
            require(amount <= maxTxLimit, "Transaction limit exceeds");
        }
        return true;
    }

    function _isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _simpleSwap(address recipient, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }
}