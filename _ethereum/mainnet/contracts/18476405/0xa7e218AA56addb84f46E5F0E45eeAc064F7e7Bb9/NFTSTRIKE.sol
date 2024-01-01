/**
 *Submitted for verification at Etherscan.io on 2023-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}




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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

contract NFTSTRIKE is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "NFT STRIKE";
    string public constant symbol = "NFTS";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 10000000000 * (10**uint256(decimals));
    uint256 private _maxTxAmount = (_totalSupply * 2) / 100;
    uint256 private _maxWalletSize = (_totalSupply * 2) / 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _liquidityFee = 2;
    uint256 private _buybackFee = 2;
    uint256 private _marketingFee = 1;
    uint256 private _devFee = 1;
    uint256 private _totalFee = 6;
    uint256 private _feeDenominator = 100;

    address private _marketingFeeReceiver =
        0x09F742130b672669fF16aa2fdA515F3473ca8aFa;
    address private _buybackFeeReceiver =
        0x2aAcc1ae2f82b6b45E067eC517dDEBDBab8E9e31;
    address private _devFeeReceiver =
        0x1Fc4a0124cD269A8E13533e100aCA377A7975Cb2;

    uint256 private _launchedAt;

    bool private _swapEnabled = true;
    uint256 private _swapThreshold = (_totalSupply / 1000) * 3; // 0.3%
    bool private _inSwap;
    bool private _isSwapBackEnabled;

    address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    IUniswapV2Factory private uniswapV2Factory;

    constructor(address initialOwner, address uniswapFactoryAddress)
        Ownable(initialOwner)
    {
        uniswapV2Factory = IUniswapV2Factory(uniswapFactoryAddress);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue
            )
        );
        return true;
    }

    function isOwner(address account) public view returns (bool) {
        return owner() == account;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return owner() == adr;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        if (_inSwap) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (recipient != uniswapV2Pair && recipient != DEAD) {}
            if (shouldSwapBack()) {
                swapBack();
            }
            if (!launched() && recipient == uniswapV2Pair) {
                require(_balances[sender] > 0);
                launch();
            }
            _balances[sender] = _balances[sender].sub(
                amount
            );
            uint256 amountReceived = takeFee(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[sender] = _balances[sender].sub(
            amount
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount
            .mul(getTotalFee(receiver == uniswapV2Pair))
            .div(_feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        uint256 multiplier = AntiDumpMultiplier();
        if (selling) {
            return _totalFee.mul(multiplier);
        }
        return _totalFee;
    }

    function AntiDumpMultiplier() private view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - _launchedAt;
        uint256 hour = 3600;
        if (timeSinceStart > 1 * hour) {
            return 1;
        } else {
            return 2;
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != uniswapV2Pair &&
            !_inSwap &&
            _swapEnabled &&
            _balances[address(this)] >= _swapThreshold;
    }

    function swapBack() internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance
            .mul(_liquidityFee)
            .div(_totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path
        );
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _totalFee.sub(_liquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB
            .mul(_liquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 amountBNBbuyback = amountBNB.mul(_buybackFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(
            totalBNBFee
        );
        uint256 amountBNBDev = amountBNB -
            amountBNBLiquidity -
            amountBNBbuyback -
            amountBNBMarketing;

        (bool MarketingSuccess, ) = payable(_marketingFeeReceiver).call{
            value: amountBNBMarketing,
            gas: 30000
        }("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        (bool BuyBackSuccess, ) = payable(_buybackFeeReceiver).call{
            value: amountBNBbuyback,
            gas: 30000
        }("");
        require(BuyBackSuccess, "receiver rejected ETH transfer");
        (bool DevSuccess, ) = payable(_devFeeReceiver).call{
            value: amountBNBDev,
            gas: 30000
        }("");
        require(DevSuccess, "receiver rejected ETH transfer");

        addLiquidity(amountToLiquify, amountBNBLiquidity);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal {
        require(
            path[0] == address(this) && path[path.length - 1] == WETH,
            "Invalid path"
        );
        require(path.length > 1, "Invalid path");
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(
            amountIn,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Slippage too high"
        );
        uniswapV2Router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {
        if (tokenAmount > 0) {
            uniswapV2Router.addLiquidityETH{value: BNBAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AutoLiquify(BNBAmount, tokenAmount);
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal {
        require(path[path.length - 1] == WETH, "Invalid path");
        require(path.length > 1, "Invalid path");
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(
            amountIn,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Slippage too high"
        );
        uniswapV2Router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function launched() internal view returns (bool) {
        return _launchedAt != 0;
    }

    function launch() internal {
        _launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxWalletSize = amount;
    }

    function setFees(
        uint256 liquidityFee,
        uint256 buybackFee,
        uint256 devFee,
        uint256 marketingFee,
        uint256 feeDenominator
    ) external onlyOwner {
        _liquidityFee = liquidityFee;
        _devFee = devFee;
        _buybackFee = buybackFee;
        _marketingFee = marketingFee;
        _totalFee = liquidityFee.add(buybackFee).add(marketingFee);
        _feeDenominator = feeDenominator;
    }

    function setFeeReceiver(
        address marketingFeeReceiver,
        address buybackFeeReceiver
    ) external onlyOwner {
        _marketingFeeReceiver = marketingFeeReceiver;
        _buybackFeeReceiver = buybackFeeReceiver;
    }

    function setSwapBackSettings(bool enabled, uint256 amount)
        external
        onlyOwner
    {
        _swapEnabled = enabled;
        _swapThreshold = amount;
    }

    function setUniswapRouter(address routerAddress) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = uniswapV2Factory.createPair(address(this), WETH);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
}