/* RiceProtect.com

Simply Protect $RICE

Website: https://riceprotect.com
Docs: https://docs.riceprotect.com/
Twitter: https://x.com/riceprotect
Telegram: https://t.me/RiceProtect

*/

// Sources flattened with hardhat v2.17.1 https://hardhat.org

// SPDX-License-Identifier: MIT AND SEE

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.6.2;

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// Original license: SPDX_License_Identifier: SEE

pragma solidity 0.8.21;

interface IVaultProtect {
    function depositInternal(address from, uint256 amount) external;
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
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
}

contract RiceProtect is ERC20Detailed, Ownable {
    IUniswapV2Router02 public router;
    address public pair;
    IVaultProtect public vaultProtect;
    address public RiceYield;
    address public marketingAddress;

    uint256 public debaseTime = 1 hours;
    uint256 public latestDebase;
    uint256 public debaseStartedAt;
    uint256 public currentEpoch;

    bool public autoDebase;
    bool public claimStatus = false;

    uint8 private constant DECIMALS = 9;

    uint256 private constant INITIAL_TOKENS_SUPPLY =
        500_000_000 * 10 ** DECIMALS;

    uint256 private constant TOTAL_PARTS =
        type(uint256).max - (type(uint256).max % INITIAL_TOKENS_SUPPLY);

    uint256 private _totalSupply;
    uint256 private _fragment;
    uint256 private _initFragment;

    // tax
    uint256 public marketing = 2;
    uint256 public rewardsFee = 3;

    uint256 private _initialTax = 30;
    uint256 private _reduceTaxAt = 30;

    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    bool public limitsInEffect = true;
    bool public tradingEnable = false;

    uint256 public swapbackPercent = 5; // 0.5%
    uint256 public maxWallet = (INITIAL_TOKENS_SUPPLY * 2) / 100; // 2%
    uint256 public maxAmount = (INITIAL_TOKENS_SUPPLY * 2) / 100; // 2%

    mapping(address => bool) public _isProtected;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => uint256) private _partBalances;
    mapping(address => mapping(address => uint256)) private _allowedTokens;

    address[] private _protected;

    event Debase(uint256 time, uint256 supply);

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor(
        address _vaultProtect,
        address _RiceYield
    ) ERC20Detailed("Rice Protect", "RICE", DECIMALS) {
        router = IUniswapV2Router02(
            address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
        );

        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        vaultProtect = IVaultProtect(_vaultProtect);
        RiceYield = _RiceYield;
        marketingAddress = _msgSender();

        _totalSupply = INITIAL_TOKENS_SUPPLY;
        _partBalances[_msgSender()] = TOTAL_PARTS;
        _fragment = TOTAL_PARTS / (_totalSupply);
        _initFragment = _fragment;

        protectAddress(address(this), true);
        protectAddress(address(vaultProtect), true);

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(router)] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[_vaultProtect] = true;

        _allowedTokens[_msgSender()][address(router)] = type(uint256).max;
        _allowedTokens[address(this)][address(router)] = type(uint256).max;

        emit Transfer(
            address(0x0),
            address(_msgSender()),
            balanceOf(_msgSender())
        );
    }

    function totalSupply() external view override returns (uint256) {
        if (_protected.length == 0) return _totalSupply;

        uint256 totalProtectExcluded;
        uint256 totalProtectIncluded;

        for (uint256 i = 0; i < _protected.length; i++) {
            totalProtectExcluded +=
                _partBalances[_protected[i]] /
                _initFragment;
            totalProtectIncluded += _partBalances[_protected[i]] / _fragment;
        }

        return _totalSupply - totalProtectIncluded + totalProtectExcluded;
    }

    function allowance(
        address owner_,
        address spender
    ) external view override returns (uint256) {
        return _allowedTokens[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        if (_isProtected[who]) {
            return _partBalances[who] / _initFragment;
        }
        return _partBalances[who] / (_fragment);
    }

    function shouldDebase() public view returns (bool) {
        uint256 times = (block.timestamp - latestDebase) / debaseTime;
        return latestDebase > 0 && times > 0 && autoDebase;
    }

    function transfer(
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (!inSwap && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            require(tradingEnable, "Trading not live");

            uint256 totalFee = rewardsFee + marketing;

            if (from == pair && _buyCount < _reduceTaxAt) {
                totalFee = _initialTax;
                _buyCount++;
            }

            if (to == pair && _sellCount < _reduceTaxAt) {
                totalFee = _initialTax;
                _sellCount++;
            }

            if (limitsInEffect) {
                if (from == pair || to == pair) {
                    require(amount <= maxAmount, "Max Tx Exceeded");
                }
                if (to != pair && to != address(vaultProtect)) {
                    require(
                        balanceOf(to) + amount <= maxWallet,
                        "Max Wallet Exceeded"
                    );
                }
            }

            uint256 fee = (amount * totalFee) / 100;
            amount = amount - fee;

            _transfer(from, address(this), fee);

            uint256 riceBalance = balanceOf(address(this));
            uint256 swapbackAmount = (_totalSupply * swapbackPercent) / 1000;
            if (to == pair) {
                if (riceBalance >= swapbackAmount) {
                    swapBack();
                }
                if (shouldDebase()) {
                    try this.manualDebase() {} catch {}
                }
            }
        }

        (uint256 fromAmount, uint256 toAmount) = getPartAmountBeforeTx(
            from,
            to,
            amount
        );

        _partBalances[from] -= fromAmount;
        _partBalances[to] += toAmount;

        if (to == address(vaultProtect)) {
            try vaultProtect.depositInternal(from, amount) {} catch {}
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function getPartAmountBeforeTx(
        address from,
        address to,
        uint256 amount
    ) public view returns (uint256, uint256) {
        uint256 excludeAmount = amount * _initFragment;
        uint256 includeAmount = amount * _fragment;

        // exclude -> exclude
        if (_isProtected[from] && _isProtected[to]) {
            return (excludeAmount, excludeAmount);
        }
        // exclude -> include
        if (_isProtected[from] && !_isProtected[to]) {
            return (excludeAmount, includeAmount);
        }
        // include -> include
        if (!_isProtected[from] && !_isProtected[to]) {
            return (includeAmount, includeAmount);
        }
        // include -> exclude
        return (includeAmount, excludeAmount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedTokens[from][_msgSender()] != type(uint256).max) {
            require(
                _allowedTokens[from][_msgSender()] >= value,
                "Insufficient Allowance"
            );
            _allowedTokens[from][_msgSender()] =
                _allowedTokens[from][_msgSender()] -
                (value);
        }
        _transfer(from, to, value);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 oldValue = _allowedTokens[_msgSender()][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[_msgSender()][spender] = 0;
        } else {
            _allowedTokens[_msgSender()][spender] =
                oldValue -
                (subtractedValue);
        }
        emit Approval(
            _msgSender(),
            spender,
            _allowedTokens[_msgSender()][spender]
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        _allowedTokens[_msgSender()][spender] =
            _allowedTokens[_msgSender()][spender] +
            (addedValue);
        emit Approval(
            _msgSender(),
            spender,
            _allowedTokens[_msgSender()][spender]
        );
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) public override returns (bool) {
        _allowedTokens[_msgSender()][spender] = value;
        emit Approval(_msgSender(), spender, value);
        return true;
    }

    function debase() private {
        uint256 times = (block.timestamp - latestDebase) / debaseTime;

        latestDebase = block.timestamp;

        currentEpoch += times;

        for (uint256 i = 0; i < times; i++) {
            uint256 supplyDelta = (_totalSupply * 26) / 10000; // 0.26%

            unchecked {
                _totalSupply = _totalSupply - supplyDelta;
                _fragment = TOTAL_PARTS / (_totalSupply);
            }

            emit Debase(block.timestamp, _totalSupply);
        }

        IUniswapV2Pair(pair).sync();
    }

    function protectAddress(address account, bool _status) public onlyOwner {
        if (_status) {
            _isProtected[account] = true;
            _protected.push(account);
        } else {
            for (uint256 i = 0; i < _protected.length; i++) {
                if (_protected[i] == account) {
                    _protected[i] = _protected[_protected.length - 1];
                    _isProtected[account] = false;
                    _protected.pop();
                    break;
                }
            }
        }
    }

    function manualDebase() public {
        require(shouldDebase(), "Not in time");
        debase();
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnable, "Trading Live Already");
        tradingEnable = true;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Limits already removed");
        limitsInEffect = false;
    }

    function excludedFromFees(
        address _address,
        bool _value
    ) external onlyOwner {
        isExcludedFromFee[_address] = _value;
    }

    function startDebase(bool _status) external onlyOwner {
        autoDebase = _status;
        latestDebase = block.timestamp;
        debaseStartedAt = block.timestamp;
    }

    function updateVaultProtect(address _newAddress) external onlyOwner {
        protectAddress(address(vaultProtect), false);
        vaultProtect = IVaultProtect(_newAddress);
        isExcludedFromFee[_newAddress] = true;
        protectAddress(_newAddress, true);
    }

    function updateRiceYield(address _newRiceYield) external onlyOwner {
        RiceYield = _newRiceYield;
    }

    function swapBack() public swapping {
        uint256 ethBeforeSwap = address(this).balance;
        uint256 swapbackAmount = (_totalSupply * swapbackPercent) / 1000;
        swapTokensForETH(swapbackAmount);
        uint256 totalETH = address(this).balance - ethBeforeSwap;
        uint256 totalFee = marketing + rewardsFee;
        uint256 amountForRiceYield = (totalETH * rewardsFee) / totalFee;

        if (amountForRiceYield > 0) {
            (bool success, ) = payable(RiceYield).call{
                value: amountForRiceYield
            }("");
            require(success, "Failed to send ETH to RiceYield");
        }

        if (address(this).balance > 0) {
            (bool success, ) = payable(marketingAddress).call{
                value: address(this).balance
            }("");
            require(success, "Failed to send ETH to Marketing");
        }
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount
            path,
            address(address(this)),
            block.timestamp
        );
    }

    receive() external payable {}
}