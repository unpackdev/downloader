/**
 */
   /*/$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $                                                               $
   $               Capitalism Contract                             $
   $                                                               $
   $  "Bulls make money, Bears make money, Capitalist Win."   $
   $                                                               $
   $                      $.$     $$$     .$.                      $
   $                     $   $   $   $   $   $                     $
   $                      $.$     $$$     .$.                      $
   $                                                               $
   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
*/

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;
 
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
 
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Emits a {Transfer} event. Returns a boolean value indicating success.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over caller's tokens.
     * Beware: changing an allowance might cause a race condition.
     * Emits an {Approval} event. Returns a boolean value indicating success.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` with allowance check.
     * Deducts `amount` from caller's allowance. Emits a {Transfer} event.
     * Returns a boolean value indicating success.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the number of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining tokens that `spender` can spend for `owner`.
     * Default is zero. Changes when {approve} or {transferFrom} is invoked.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

 
 
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataExtension is IERC20 {
    
    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
    
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);
 
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
 

contract ERC20 is Context, IERC20, IERC20MetadataExtension {
string private _name;
    string private _symbol;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
    public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    
    function _approve(
    address owner,
    address spender,
    uint256 amount
) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
}

function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
) internal virtual {}

function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
        require(
            currentAllowance >= amount,
            "ERC20: insufficient allowance"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}

function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
) internal virtual {}


}

 
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
 
    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
 
    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
 
    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
 
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
 
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
 
    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
 
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
 
    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
 
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
  
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);
 
    function allPairsLength() external view returns (uint256);
 
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function feeToSetter() external view returns (address);
 
    function setFeeToSetter(address) external;

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function setFeeTo(address) external;
}
  
interface IUniswapV2Router01 {
    function WETH() external pure returns (address);
    
    function factory() external pure returns (address);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
    
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}
 
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
}
 
contract Capitalism is ERC20, Ownable {
    using SafeMath for uint256;

    bool public swapEnabled = false;
    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 private buyDevFee;
    uint256 public maxWallet;
    uint256 private tokensForMarketing;
    uint256 public buyTotalFees;
    uint256 private tokensForDevelopment;

    address public markWallet;
    address public devWallet;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public burnsPartnershipsCEXWallet;

    uint256 private sellDevFee;
    uint256 public swapTokensAtAmount;
    uint256 private previousFee;
    uint256 private buyMarkFee;
    uint256 public sellTotalFees;
    uint256 private sellMarkFee;

    bool public tradingActive = false;

    IUniswapV2Router02 public immutable uniswapV2Router;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event developmentWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
 
    constructor(address _marketingWallet, address _developmentWallet, address _burnsPartnershipsCEXWallet) 
        ERC20(unicode"Capitalism", unicode"CAP") {

        uint256 totalSupply = 21_000_000 ether;

        // Set the router
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        // Set maximum transaction and wallet limits
        maxTransactionAmount = (totalSupply) / 50;
        maxWallet = (totalSupply) / 50;

        // Set fee structures. Start at 10/30. Renounce at 0/0
        buyMarkFee = 5;
        buyDevFee = 5;
        sellMarkFee = 15;
        sellDevFee = 15;
        buyTotalFees = buyMarkFee + buyDevFee;
        sellTotalFees = sellMarkFee + sellDevFee;
        previousFee = sellTotalFees;

        swapTokensAtAmount = (totalSupply * 5) / 10000;

        // Set wallet addresses
        markWallet = _marketingWallet;
        devWallet = _developmentWallet;
        burnsPartnershipsCEXWallet = _burnsPartnershipsCEXWallet;

        // Exclude addresses from fees
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(markWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(burnsPartnershipsCEXWallet, true);
        excludeFromFees(deadAddress, true);

        // Exclude addresses from max transaction
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(markWallet, true);
        excludeFromMaxTransaction(devWallet, true);
        excludeFromMaxTransaction(burnsPartnershipsCEXWallet, true);
        excludeFromMaxTransaction(deadAddress, true);

        // Minting token logic
        uint256 partnershipsPlusTokenAmount = (totalSupply * 50) / 100;
        uint256 contractAmount = totalSupply - partnershipsPlusTokenAmount;

        _mint(burnsPartnershipsCEXWallet, partnershipsPlusTokenAmount);
        _mint(address(this), contractAmount);
    }
 
    receive() external payable {}
 
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
 
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        uint256 tokensInWallet = balanceOf(address(this));

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensInWallet, 
            0,
            0,
            owner(),
            block.timestamp
        );

        tradingActive = true;
        swapEnabled = true;
    }
    
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMarketingWallet(address newMarketingWallet)
        external
        onlyOwner
    {
        require(newMarketingWallet != address(0), "ERC20: Address 0");
        address prevWallet = markWallet;
        markWallet = newMarketingWallet;
        emit marketingWalletUpdated(markWallet, prevWallet);
    }

    function updateDevelopmentWallet(address newDevelopmentWallet)
        external
        onlyOwner
    {
        require(newDevelopmentWallet != address(0), "ERC20: Address 0");
        address prevWallet = devWallet;
        devWallet = newDevelopmentWallet;
        emit developmentWalletUpdated(devWallet, prevWallet);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _developmentFee
    ) external onlyOwner {
        buyMarkFee = _marketingFee;
        buyDevFee = _developmentFee;
        buyTotalFees = buyMarkFee + buyDevFee;
        require(buyTotalFees <= 30, "ERC20: Must keep fees at 30% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _developmentFee
    ) external onlyOwner {
        sellMarkFee = _marketingFee;
        sellDevFee = _developmentFee;
        sellTotalFees = sellMarkFee + sellDevFee;
        previousFee = sellTotalFees;
        require(sellTotalFees <= 30, "ERC20: Must keep fees at 30% or less");
    }

    function updateMaxWalletAndTxnAmount(
        uint256 newTxAmount,
        uint256 newMaxWalletAmount
    ) external onlyOwner {
        require(
            newTxAmount >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        require(
            newMaxWalletAmount >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newMaxWalletAmount;
        maxTransactionAmount = newTxAmount;
    }

    function excludeFromFees(address acc, bool isExcluded) public onlyOwner {
        _isExcludedFromFees[acc] = isExcluded;
        emit ExcludeFromFees(acc, isExcluded);
    }

    function excludeFromMaxTransaction(address accountAddr, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[accountAddr] = isEx;
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }
    function withdrawStuckTokens(address token) public onlyOwner {
        uint256 tokenAmount = IERC20(token).balanceOf(address(this));
        require(tokenAmount > 0, "No tokens");
        IERC20(token).transfer(msg.sender, tokenAmount);
    }

    function _setAutomatedMarketMakerPair(address pairAddr, bool val) private {
        automatedMarketMakerPairs[pairAddr] = val;
        emit SetAutomatedMarketMakerPair(pairAddr, val);
    }

    function isExcludedFromFees(address acc) public view returns (bool) {
        return _isExcludedFromFees[acc];
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        bool isTrading = (sender != owner() && recipient != owner() && recipient != address(0) && recipient != deadAddress && !swapping);
        if (isTrading) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[sender] || _isExcludedFromFees[recipient],
                    "ERC20: Trading is not active."
                );
            }
            
            bool isBuy = automatedMarketMakerPairs[sender] && !_isExcludedMaxTransactionAmount[recipient];
            bool isSell = automatedMarketMakerPairs[recipient] && !_isExcludedMaxTransactionAmount[sender];
            
            if (isBuy) {
                require(amount <= maxTransactionAmount, "ERC20: Buy transfer amount exceeds the maxTransactionAmount.");
                require(amount + balanceOf(recipient) <= maxWallet, "ERC20: Max wallet exceeded");
            } else if (isSell) {
                require(amount <= maxTransactionAmount, "ERC20: Sell transfer amount exceeds the maxTransactionAmount.");
            } else if (!_isExcludedMaxTransactionAmount[recipient]) {
                require(amount + balanceOf(recipient) <= maxWallet, "ERC20: Max wallet exceeded");
            }
        }

        uint256 tokensInContract = balanceOf(address(this));
        bool canSwapTokens = tokensInContract >= swapTokensAtAmount;

        if (canSwapTokens && swapEnabled && !swapping && !automatedMarketMakerPairs[sender] && !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool applyFee = !swapping && (!_isExcludedFromFees[sender] || !_isExcludedFromFees[recipient]);
        uint256 totalFees = 0;

        if (applyFee) {
            uint256 feePercent = automatedMarketMakerPairs[recipient] ? sellTotalFees : (automatedMarketMakerPairs[sender] ? buyTotalFees : 0);
            if (feePercent > 0) {
                totalFees = amount.mul(feePercent).div(100);
                tokensForMarketing += (totalFees * (automatedMarketMakerPairs[recipient] ? sellMarkFee : buyMarkFee)) / feePercent;
                tokensForDevelopment += (totalFees * (automatedMarketMakerPairs[recipient] ? sellDevFee : buyDevFee)) / feePercent;

                super._transfer(sender, address(this), totalFees);
                amount -= totalFees;
            }
        }

        super._transfer(sender, recipient, amount);
        sellTotalFees = previousFee;
    }

    function swapTokensForEth(uint256 amount) private {
        address[] memory paths = new address[](2);
        paths[0] = address(this);
        paths[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), amount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            paths,
            address(this),
            block.timestamp
        );
    }
 
    function swapBack() private {
        uint256 totalTokensToSwap = tokensForDevelopment + tokensForMarketing;
        bool success;

        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractTokenBalance > swapTokensAtAmount * 20) {
            contractTokenBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractTokenBalance);

        uint256 initialBalanceETH = address(this).balance;
        uint256 marketingETH = initialBalanceETH.mul(tokensForMarketing).div(totalTokensToSwap);

        tokensForDevelopment = 0;
        tokensForMarketing = 0;

        (success, ) = address(markWallet).call{value: marketingETH}("");
        (success, ) = address(devWallet).call{value: address(this).balance}("");
    }
}