/*

88                        88                           ,adba,              88                        88
88                        88                           8I  I8              88                        88
88                        88                           "8bdP'              88                        88
88,dPPYba,   88       88  88,dPPYba,   88       88    ,d8"8b  88   ,adPPYb,88  88       88   ,adPPYb,88  88       88
88P'    "8a  88       88  88P'    "8a  88       88  .dP'   Yb,8I  a8"    `Y88  88       88  a8"    `Y88  88       88
88       d8  88       88  88       d8  88       88  8P      888'  8b       88  88       88  8b       88  88       88
88b,   ,a8"  "8a,   ,a88  88b,   ,a8"  "8a,   ,a88  8b,   ,dP8b   "8a,   ,d88  "8a,   ,a88  "8a,   ,d88  "8a,   ,a88
8Y"Ybbd8"'    `"YbbdP'Y8  8Y"Ybbd8"'    `"YbbdP'Y8  `Y8888P"  Yb   `"8bbdP"Y8   `"YbbdP'Y8   `"8bbdP"Y8   `"YbbdP'Y8

https://t.me/bubududuerc
https://twitter.com/BUBU_erc
https://twitter.com/DUDU_erc
https://www.bubududu.xyz/

*/
// SPDX-License-Identifier: Unlicensed

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/prod/Base.sol


pragma solidity ^0.8.0;






abstract contract BaseContract is Ownable {

  using SafeMath for uint256;

  struct BubuAccounting{
    uint256 affiliates;
    uint256 team;
    uint256 staking;
  }

  struct DuduAccounting{
    uint256 affiliates;
    uint256 team;
    uint256 staking;
    uint256 burn;
  }

  struct EthAccounting{
    uint256 affiliates;
    uint256 team;
    uint256 staking;
  }

  // ACCOUNTING
  BubuAccounting public bubuAccounting;

  DuduAccounting public duduAccounting;

  EthAccounting public ethAccounting;

  // CHAINLINK CONSTANTS
  address public constant CHAINLINK_AGGREGATOR_USD_ETH = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
  address public constant CHAINLINK_AGGREGATOR_LINK_ETH = 0xDC530D9457755926550b59e8ECcdaE7624181557;

  // SWAP CONSTANTS
  address public constant UNISWAPV2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  uint256 public ENTRY_PRICE_USDT = 88.88 * 10**6; // 88.88 usdt
  uint256 public ETH_ENTRY_PRICE_INCREASE_PERCENTAGE = 20; // 20%
  uint256 public UINT32_MAX = 2**32-1;

  // CONSTRUCTOR ARGS
  AggregatorV3Interface public immutable linkToEthDataFeed;
  AggregatorV3Interface public immutable usdToEthDataFeed;
  IUniswapV2Router02 public immutable uniswapV2Router;
  IERC20 public immutable bubuToken;
  IERC20 public immutable duduToken;
  address payable public teamFeeReceiver;
  address payable public stakingFeeReceiver;

  // ACCOUNTING + SETTINGS
  uint16 public maxEntriesPerTx = 100; // owner can update
  uint256 public tip = 0.0025 ether;                      // owner can update
  bool public lockBurnEntries = true;                            // owner can update
  bool public lockInitiateDrawing;                        // owner can update
  bool public includeFreeEntriesWithMaxEntries = false;   // owner can update
  bool internal includeFreeEntries = false;
  uint32 public drawingIndex;           // internal
  uint16 public numPayoutAttempts = 5;  // owner can update

  // STATE
  mapping(address => bool) private approvedOwners;
  mapping(address => bool) public isBlacklistedFromPrizes;
  mapping(address => uint256) public amountBurned;

  // EVENTS
  event OwnerApproved(address indexed approvedOwner);
  event OwnerRevoked(address indexed revokedOwner);
  event DrawingInitiated();
  event NoEntries();
  event BurnedEntries(address sender, uint256 numEntries);
  event Received(uint256 amount);

  constructor(
    address _bubuToken,
    address _duduToken,
    address _teamFeeReceiver,
    address _stakingFeeReceiver
  ) {

    linkToEthDataFeed = AggregatorV3Interface(CHAINLINK_AGGREGATOR_LINK_ETH);
    usdToEthDataFeed = AggregatorV3Interface(CHAINLINK_AGGREGATOR_USD_ETH);
    uniswapV2Router = IUniswapV2Router02(UNISWAPV2_ROUTER_ADDRESS);

    bubuToken = IERC20(_bubuToken);
    duduToken = IERC20(_duduToken);

    teamFeeReceiver = payable(_teamFeeReceiver);
    stakingFeeReceiver = payable(_stakingFeeReceiver);
  }

  receive() external payable {
    emit Received(msg.value);
  }

  modifier refundGas {
    uint256 initialGas = gasleft();
    _;
    uint256 gasConsumed = initialGas - gasleft() + 30000;
    (bool success,) = msg.sender.call{value: gasConsumed * block.basefee + tip}("");
    require(success, "refund");
  }

  // ACCESS CONTROL--------------------------------------------------------------
  modifier onlyApprovedOwner() {
      require(msg.sender == owner() || isApprovedOwner(msg.sender), "Not an approved owner");
      _;
  }

  function approveOwner(address _approvedOwner) external onlyApprovedOwner {
    approvedOwners[_approvedOwner] = true;
    emit OwnerApproved(_approvedOwner);
  }

  function revokeOwner(address _revokedOwner) external onlyApprovedOwner {
    approvedOwners[_revokedOwner] = false;
    emit OwnerRevoked(_revokedOwner);
  }

  function isApprovedOwner(address _address) public view returns(bool) {
    return approvedOwners[_address];
  }

  // OWNER ONLY --------------------------------------------------------------
  function setTip(uint256 _tip) public onlyApprovedOwner {
    tip = _tip;
  }

  function setLockInitiateDrawing(bool _lockInitiateDrawing) public onlyApprovedOwner {
    lockInitiateDrawing = _lockInitiateDrawing;
  }

  function setIncludeFreeEntriesWithMaxEntries(bool _includeFreeEntriesWithMaxEntries) public onlyApprovedOwner {
    includeFreeEntriesWithMaxEntries = _includeFreeEntriesWithMaxEntries;
  }

  function setLockBurnEntries(bool _lockBurnEntries) public onlyApprovedOwner {
    lockBurnEntries = _lockBurnEntries;
  }

  function setmaxEntriesPerTx(uint16 _maxEntriesPerTx) public onlyApprovedOwner {
    maxEntriesPerTx = _maxEntriesPerTx;
  }

  function setNumPayoutAttempts(uint16 _numPayoutAttempts) public onlyApprovedOwner {
    require(_numPayoutAttempts > 0, 'must be a value higher than 0');
    numPayoutAttempts = _numPayoutAttempts;
  }

  function setBlacklistedFromPrizes(address _user, bool isBlacklisted) public onlyApprovedOwner {
    // only to be used if someone tries to exploit our on-chain token price lookup.
    isBlacklistedFromPrizes[_user] = isBlacklisted;
  }

  function setTeamFeeReciever(address payable _teamFeeReceiver) public onlyApprovedOwner {
    teamFeeReceiver = _teamFeeReceiver;
  }

  function setStakingFeeReceiver(address payable _stakingFeeReceiver) public onlyApprovedOwner {
    stakingFeeReceiver = _stakingFeeReceiver;
  }

  function setEntryPriceUSDT(uint256 _entryPriceUSDT) public onlyApprovedOwner {
    require(_entryPriceUSDT > 0, 'must be a value higher than 0');
    ENTRY_PRICE_USDT = _entryPriceUSDT * 10**6;
  }

  function setEthEntryPriceIncreasePercentage(uint256 _ethEntryPriceIncreasePercentage) public onlyApprovedOwner {
    require(_ethEntryPriceIncreasePercentage > 0, 'must be a value higher than 0');
    ETH_ENTRY_PRICE_INCREASE_PERCENTAGE = _ethEntryPriceIncreasePercentage;
  }

  // RESCUE ------------------------------------------------------------------
  /**
   * @dev rescues eth from contract
   */
  function rescueEth() public onlyApprovedOwner {
    (bool success,) = owner().call{value: address(this).balance}("");
    require(success);
  }

  /**
   * @dev rescues erc20 tokens sent directly to vault
   */
  function rescueERC20(address token, uint256 amount) public onlyApprovedOwner {
    IERC20(token).transfer(owner(), amount);
  }

  function ethRequiredForUSD(uint256 _numEntries) public view returns (uint256) {
    (,int price,,,) = usdToEthDataFeed.latestRoundData();
    require(price > 0, "Invalid ETH price");
    uint256 ENTRY_ETH_PRICE_USDT = ENTRY_PRICE_USDT * (100 + ETH_ENTRY_PRICE_INCREASE_PERCENTAGE);
    uint256 usdAmount = ENTRY_ETH_PRICE_USDT * _numEntries;
    return (usdAmount * 1e18)/uint256(price);
  }

  /**
   * @dev calculates how many tokens are needed for _numEntries
   */
  function getEntryPrice(uint256 _numEntries, address tokenAddress) public view returns (uint256) {
    address[] memory tokenWethUsdtPath = new address[](3);
    tokenWethUsdtPath[0] = tokenAddress;
    tokenWethUsdtPath[1] = WETH_ADDRESS;
    tokenWethUsdtPath[2] = USDT_ADDRESS;

    return uniswapV2Router.getAmountsIn(ENTRY_PRICE_USDT * _numEntries, tokenWethUsdtPath)[0];
  }

  function burnEntriesCheck(uint16 _numEntries) internal view returns (uint256){
    address sender = msg.sender;

    entryCondition();

    require(tx.origin == sender, "no contracts"); // prevent bots
    require(!lockBurnEntries, "no burn");
    require(!lockInitiateDrawing, "in progress");
    require(!isBlacklistedFromPrizes[sender], "shoo");

    uint256 _allEntries;

    if(includeFreeEntries){
      uint256 _freeEntries = _numEntries / 5;
      _allEntries = _numEntries + _freeEntries;
    } else {
      _allEntries = _numEntries;
    }

    if(!includeFreeEntriesWithMaxEntries)
      require(_numEntries <= maxEntriesPerTx, "tx limit");
    else
      require(_allEntries <= maxEntriesPerTx, "tx limit");
    return _allEntries;
  }

  function afterBurnAddEntries(uint256 amountInMin, uint256 _allEntries) internal {
    address sender = msg.sender;
    amountBurned[sender] += amountInMin;
    uint i;
    for (;i < _allEntries;) {
        addEntry(sender);
        unchecked {++i;}
    }
    emit BurnedEntries(sender, _allEntries);
  }

  function entryCondition() internal view virtual {}

  function addEntry(address sender) internal virtual {}

  function getRandomEntryIndex(uint256 randomness, uint32 i, uint256 total) internal pure returns (uint256) {
    require(total > 0, "No entries available");

    uint256 simulatedRandomness = uint256(keccak256(abi.encode(randomness, i)));
    uint256 index = simulatedRandomness % total;

    return index;
  }


  /**
   * @dev returns max tokens _user can burn at once
   */
  function getMaxBurnableEntries(address _user, address burnTokenAddress) public view returns (uint16) {
    if (isBlacklistedFromPrizes[_user]) {
      return 0;
    }
    address[] memory tokenWethUsdtPath = new address[](3);
    IERC20 burnToken = IERC20(burnTokenAddress);
    tokenWethUsdtPath[0] = burnTokenAddress;
    tokenWethUsdtPath[1] = WETH_ADDRESS;
    tokenWethUsdtPath[2] = USDT_ADDRESS;
    uint256 tokenHoldings = burnToken.balanceOf(_user);
    uint256 usdtOut = uniswapV2Router.getAmountsOut(tokenHoldings, tokenWethUsdtPath)[2];
    uint16 numEntries = uint16(usdtOut / ENTRY_PRICE_USDT);
    if (numEntries > maxEntriesPerTx) {
        numEntries = maxEntriesPerTx;
    }
    return numEntries;
  }

  function enterWithBUBU(uint16 _numEntries, address _affiliates) public {
    address sender = msg.sender;
    uint256 _allEntries = burnEntriesCheck(_numEntries);

    // transfer entry amount
    uint256 amountInMin = getEntryPrice(_numEntries, address(bubuToken));

    if (_affiliates != address(0) && _affiliates != sender) {
      bubuAccounting.affiliates > 0 && bubuToken.transferFrom(sender, _affiliates, amountInMin * bubuAccounting.affiliates/100);
      bubuAccounting.staking > 0 && bubuToken.transferFrom(sender, stakingFeeReceiver, amountInMin * bubuAccounting.staking/100);
      bubuAccounting.team > 0 && bubuToken.transferFrom(sender, teamFeeReceiver, amountInMin * bubuAccounting.team/100);
    } else {
      (bubuAccounting.affiliates > 0 || bubuAccounting.team > 0) && bubuToken.transferFrom(sender, teamFeeReceiver, amountInMin * (bubuAccounting.affiliates + bubuAccounting.team)/100);
      bubuAccounting.staking > 0 && bubuToken.transferFrom(sender, stakingFeeReceiver, amountInMin * bubuAccounting.staking/100);
    }

    uint256 remainder = 100 - (bubuAccounting.affiliates + bubuAccounting.staking + bubuAccounting.team);

    if(remainder > 0){
      bubuToken.transferFrom(sender, address(this), amountInMin * remainder/100);
    }

    afterBurnAddEntries(amountInMin, _allEntries);
  }

  function enterWithDUDU(uint16 _numEntries, address _affiliates) public {
    address sender = msg.sender;
    uint256 _allEntries = burnEntriesCheck(_numEntries);

    // transfer entry amount
    uint256 amountInMin = getEntryPrice(_numEntries, address(duduToken));
    duduAccounting.burn > 0 && duduToken.transferFrom(sender, DEAD_ADDRESS, amountInMin * duduAccounting.burn/100);

    if (_affiliates != address(0) && _affiliates != sender) {
      duduAccounting.affiliates > 0 && duduToken.transferFrom(sender, _affiliates, amountInMin * duduAccounting.affiliates/100);
      duduAccounting.staking > 0 && duduToken.transferFrom(sender, stakingFeeReceiver, amountInMin * duduAccounting.staking/100);
      duduAccounting.team > 0 && duduToken.transferFrom(sender, teamFeeReceiver, amountInMin * duduAccounting.team/100);
    } else {
      (duduAccounting.affiliates > 0 || duduAccounting.team > 0) && duduToken.transferFrom(sender, teamFeeReceiver, amountInMin * (duduAccounting.affiliates + duduAccounting.team)/100);
      duduAccounting.staking > 0 && duduToken.transferFrom(sender, stakingFeeReceiver, amountInMin * duduAccounting.staking/100);
    }

     uint256 remainder = 100 - (duduAccounting.affiliates + duduAccounting.staking + duduAccounting.team + duduAccounting.burn);

    if(remainder > 0){
      duduToken.transferFrom(sender, address(this), amountInMin * remainder/100);
    }

    afterBurnAddEntries(amountInMin, _allEntries);
  }

  function enterWithEth(uint16 _numEntries, address payable _affiliates) public payable {
    address sender = msg.sender;
    uint256 _allEntries = burnEntriesCheck(_numEntries);
    uint256 amountInMin = ethRequiredForUSD(_numEntries);

    require(msg.value >= amountInMin, "Incorrect Ether sent!");

    if (_affiliates != address(0) && _affiliates != sender) {
      if(ethAccounting.affiliates > 0) _affiliates.transfer(msg.value * ethAccounting.affiliates/100);
      if(ethAccounting.team > 0) teamFeeReceiver.transfer(msg.value * ethAccounting.team/100);
    } else {
      if(ethAccounting.team > 0 || ethAccounting.affiliates > 0) teamFeeReceiver.transfer(msg.value * (ethAccounting.team + ethAccounting.affiliates)/100);
    }

    if(ethAccounting.staking > 0) stakingFeeReceiver.transfer(msg.value * ethAccounting.staking/100);
    afterBurnAddEntries(msg.value, _allEntries);
  }

    function setBubuAccounting(uint256 affiliates, uint256 team, uint256 staking) public onlyApprovedOwner {
    bubuAccounting = BubuAccounting({
      affiliates: affiliates,
      team: team,
      staking: staking
    });
  }

  function setDuduAccounting(uint256 affiliates, uint256 team, uint256 staking, uint256 burn) public onlyApprovedOwner {
    duduAccounting = DuduAccounting({
      affiliates: affiliates,
      team: team,
      staking: staking,
      burn: burn
    });
  }

  function setEthAccounting(uint256 affiliates, uint256 team, uint256 staking) public onlyApprovedOwner {
    ethAccounting = EthAccounting({
      team: team,
      staking: staking,
      affiliates: affiliates
    });
  }

}

// File: contracts/prod/LootPool.sol

/*

88                        88                           ,adba,              88                        88
88                        88                           8I  I8              88                        88
88                        88                           "8bdP'              88                        88
88,dPPYba,   88       88  88,dPPYba,   88       88    ,d8"8b  88   ,adPPYb,88  88       88   ,adPPYb,88  88       88
88P'    "8a  88       88  88P'    "8a  88       88  .dP'   Yb,8I  a8"    `Y88  88       88  a8"    `Y88  88       88
88       d8  88       88  88       d8  88       88  8P      888'  8b       88  88       88  8b       88  88       88
88b,   ,a8"  "8a,   ,a88  88b,   ,a8"  "8a,   ,a88  8b,   ,dP8b   "8a,   ,d88  "8a,   ,a88  "8a,   ,d88  "8a,   ,a88
8Y"Ybbd8"'    `"YbbdP'Y8  8Y"Ybbd8"'    `"YbbdP'Y8  `Y8888P"  Yb   `"8bbdP"Y8   `"YbbdP'Y8   `"8bbdP"Y8   `"YbbdP'Y8

https://t.me/bubududuerc
https://twitter.com/BUBU_erc
https://twitter.com/DUDU_erc
https://www.bubududu.xyz/

*/


pragma solidity ^0.8.0;






contract Lootpool is BaseContract {
    using SafeMath for uint256;

    //STRUCT
    struct ERC721Item {
        address contractAddress; // Address of the ERC721 contract
        uint256 tokenId; // Unique token ID
    }

    struct ERC20Item {
        address contractAddress; // Address of the ERC721 contract
        uint256 amount; // Unique token ID
    }

    struct LootpoolPrize {
        ERC721Item[] erc721Items;
        ERC20Item[] erc20Items;
        uint256 ethAmount;
    }

    struct LootpoolItem {
        ERC721Item erc721Item;
        ERC20Item erc20Item;
        uint256 ethAmount;
    }

    struct WinnerDetail {
        address winner;
        LootpoolItem prize;
    }

    LootpoolPrize public currentLootpool;

    // ALL DRAWINGS
    mapping(address => bool) private approvedOwners;
    mapping(address => uint256[]) public participantEntries;
    mapping(address => uint256) public participantEntryCount;
    mapping(uint256 => WinnerDetail[]) public winners;

    address[] public participants;

    uint256 public drawEndTime;
    bool public drawActive = false;

    event Winner(address winner, LootpoolPrize prize);
    event Loser(address loser, LootpoolPrize wouldBePrize);

    // versioning of the Loot Pool so that participantEntries mapping doesnt need to get deleted every time a loot pool finishes
    // this saves on gas
    uint256 public currentVersion = 1;
    mapping(address => uint256) private userVersion;

    constructor(
        address _bubuToken,
        address _duduToken,
        address _teamFeeReceiver,
        address _stakingFeeReceiver
    )
        BaseContract(
            _bubuToken,
            _duduToken,
            _teamFeeReceiver,
            _stakingFeeReceiver
        )
    {
        // Entry price for supported tokens and eth (also has setter functions)
        ENTRY_PRICE_USDT = 100 * 10**6; // 100 usdt;
        ETH_ENTRY_PRICE_INCREASE_PERCENTAGE = 20; // 20%

        bubuAccounting = BubuAccounting({
            affiliates: 15,
            team: 85,
            staking: 0
        });

        duduAccounting = DuduAccounting({
            affiliates: 10,
            team: 20,
            staking: 35,
            burn: 35
        });

        ethAccounting = EthAccounting({
            team: 60,
            staking: 25,
            affiliates: 15
        });
    }

    modifier drawOngoing() {
        require(
            drawActive && block.timestamp < drawEndTime,
            "No ongoing draw or draw has ended"
        );
        _;
    }

    modifier hasRewards() {
        require(
            currentLootpool.erc721Items.length > 0 ||
                currentLootpool.erc20Items.length > 0 ||
                currentLootpool.ethAmount > 0,
            "No rewards set"
        );
        _;
    }

    function startDraw(uint256 duration) external onlyApprovedOwner hasRewards {
        require(!drawActive, "Another draw is already active");
        delete participants;
        drawEndTime = block.timestamp + duration;
        drawActive = true;
    }

    function stopDraw() external onlyApprovedOwner {
        require(drawActive, "no active draw to stop");
        delete participants;
        delete drawEndTime;
        drawActive = false;
    }

    function extendDrawTime(uint256 duration) external onlyApprovedOwner {
        require(drawActive, "no active draw to stop");
        if (isDrawOngoing()) {
            drawEndTime += duration;
        } else {
            drawEndTime = block.timestamp + duration;
        }
    }

    // DRAWING CORE MECHANICS --------------------------------------------------
    function initiateDrawing() public refundGas {
        require(!lockInitiateDrawing, "in progress");
        require(block.timestamp >= drawEndTime, "Draw hasn't ended yet");
        require(drawActive, "No ongoing draw");
        require(tx.origin == msg.sender, "no contract calls");

        if (participants.length == 0) {
            emit NoEntries();
            delete participants;
            delete drawEndTime;
            drawActive = false;
        } else {
            startDraw();
        }
    }

    function startDraw() internal {
        lockInitiateDrawing = true;
        // Distribute prize without relying on Chainlink VRF
        require(lockInitiateDrawing, "not in progress");

        uint256 randomness = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number
                )
            )
        );

        address _addr;
        uint256 randomIndex;
        uint32 numWinners;
        uint32 i;
        uint256 maxNumWinners = numberOfWinners();

        for (; i < numPayoutAttempts; ) {
            if (numWinners >= maxNumWinners) break;

            randomIndex = getRandomEntryIndex(
                randomness,
                i,
                participants.length
            );
            _addr = participants[randomIndex];

            if (isBlacklistedFromPrizes[_addr]) {
                emit Loser(_addr, currentLootpool);
                unchecked {
                    ++i;
                }
                continue;
            }

            WinnerDetail memory winningDetail = drawWinner(_addr);
            emit Winner(_addr, currentLootpool);

            unchecked {
                ++numWinners;
                winners[drawingIndex].push(winningDetail);
            }

            unchecked {
                ++i;
            }
        }
        _resetAll();
        lockInitiateDrawing = false;
        drawingIndex++;
    }

    // OWNER ONLY --------------------------------------------------------------
    function setDrawState(bool _drawActive) public onlyApprovedOwner {
        drawActive = _drawActive;
    }

    // VIEWS -------------------------------------------------------------------

    function tooSoon() public view returns (bool) {
        return block.timestamp >= drawEndTime;
    }

    function isDrawOngoing() public view returns (bool) {
        return block.timestamp < drawEndTime;
    }

    function drawWinner(
        address _winner
    ) internal returns (WinnerDetail memory) {
        LootpoolItem memory prize = emptyLootpoolState();

        if (currentLootpool.ethAmount > 0) {
            // Send ETH
            payable(_winner).transfer(currentLootpool.ethAmount);
            prize.ethAmount = currentLootpool.ethAmount;
            currentLootpool.ethAmount = 0;
            return WinnerDetail({winner: _winner, prize: prize});
        } else if (currentLootpool.erc20Items.length > 0) {
            // Send an ERC20 token
            ERC20Item memory item = currentLootpool.erc20Items[
                currentLootpool.erc20Items.length - 1
            ];
            IERC20(item.contractAddress).transfer(_winner, item.amount);
            prize.erc20Item = item;
            currentLootpool.erc20Items.pop();
            return WinnerDetail({winner: _winner, prize: prize});
        } else if (currentLootpool.erc721Items.length > 0) {
            // Send an ERC721 token
            ERC721Item memory item = currentLootpool.erc721Items[
                currentLootpool.erc721Items.length - 1
            ];
            IERC721(item.contractAddress).transferFrom(
                address(this),
                _winner,
                item.tokenId
            );
            prize.erc721Item = item;
            currentLootpool.erc721Items.pop();
            return WinnerDetail({winner: _winner, prize: prize});
        }
        return WinnerDetail({winner: _winner, prize: prize});
    }

    function numberOfWinners() internal view returns (uint256) {
        uint256 erc20 = currentLootpool.erc20Items.length;
        uint256 erc721 = currentLootpool.erc721Items.length;
        uint256 eth = currentLootpool.ethAmount > 0 ? 1 : 0;
        return erc20 + erc721 + eth;
    }

    function setLootpool(
        ERC721Item[] memory _erc721Items,
        ERC20Item[] memory _erc20Items,
        uint256 _ethAmount
    ) external onlyApprovedOwner {
        // 1. Check ETH balance
        require(
            address(this).balance >= _ethAmount,
            "Contract does not have enough ETH"
        );

        // 2. Check ownership and existence of ERC721 tokens
        for (uint i = 0; i < _erc721Items.length; i++) {
            IERC721 erc721 = IERC721(_erc721Items[i].contractAddress);
            require(
                erc721.ownerOf(_erc721Items[i].tokenId) == address(this),
                "Contract does not own the ERC721 token"
            );
        }

        // 3. Check if contract has enough of each individual ERC20 token
        for (uint i = 0; i < _erc20Items.length; i++) {
            IERC20 erc20 = IERC20(_erc20Items[i].contractAddress);
            uint256 weiAmount = _erc20Items[i].amount * 1e18; // Convert the amount from ETH to wei
            require(
                erc20.balanceOf(address(this)) >= weiAmount,
                "Contract does not have enough ERC20 tokens"
            );
            _erc20Items[i].amount = weiAmount; // Update the amount in the _erc20Items array
        }

        // 4. If all checks pass, update the lootpool state
        for (uint i = 0; i < _erc721Items.length; i++) {
            currentLootpool.erc721Items.push(_erc721Items[i]);
        }
        for (uint i = 0; i < _erc20Items.length; i++) {
            currentLootpool.erc20Items.push(_erc20Items[i]);
        }
        currentLootpool.ethAmount = _ethAmount;
    }

    function resetLootpool() external onlyApprovedOwner {
        delete currentLootpool;
    }

    function _resetAll() internal {
        delete currentLootpool;
        delete participants;
        delete drawEndTime;
        drawActive = false;
        currentVersion++; // Increase the version, effectively resetting all user entries
    }

    function resetAll() public onlyApprovedOwner {
        delete currentLootpool;
        delete participants;
        delete drawEndTime;
        drawActive = false;
        currentVersion++; // Increase the version, effectively resetting all user entries
    }

    function canTransferERC20(
        address tokenAddress,
        uint256 amount
    ) public view returns (bool) {
        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        return allowance >= amount;
    }

    function canTransferERC721(
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool) {
        IERC721 nft = IERC721(nftAddress);

        // Check specific approval for this token
        address approvedAddress = nft.getApproved(tokenId);
        if (approvedAddress == address(this)) {
            return true;
        }

        // Check general approval for all tokens of the owner
        return nft.isApprovedForAll(msg.sender, address(this));
    }

    function getEntriesForParticipant(
        address _participant
    ) external view returns (uint256) {
        if (userVersion[_participant] == currentVersion) {
            return participantEntryCount[_participant];
        } else {
            return 0;
        }
    }

    function getWinningAddresses(
        uint256 _drawingIndex
    ) public view returns (WinnerDetail[] memory) {
        return winners[_drawingIndex];
    }

    function getTotalActiveEntries() public view returns (uint256) {
        return participants.length;
    }

    function addEntry(address sender) internal override drawOngoing {
        if (userVersion[sender] != currentVersion) {
            userVersion[sender] = currentVersion;
            participantEntryCount[sender] = 0; // Reset the entry count
        }
        participants.push(sender);
        participantEntries[sender].push(drawingIndex);
        participantEntryCount[sender]++; // Increase the entry count
    }

    function emptyLootpoolState() internal pure returns (LootpoolItem memory) {
        return
            LootpoolItem({
                erc721Item: ERC721Item({
                    contractAddress: address(0),
                    tokenId: 0
                }),
                erc20Item: ERC20Item({contractAddress: address(0), amount: 0}),
                ethAmount: 0
            });
    }

    function getErc721ItemsCount() public view returns (uint256) {
        return currentLootpool.erc721Items.length;
    }

    function getErc20ItemsCount() public view returns (uint256) {
        return currentLootpool.erc20Items.length;
    }

    function getLootPoolEthAmount() public view returns (uint256) {
        return currentLootpool.ethAmount;
    }

    enum TokenType {
        ERC721,
        ERC20
    }

    function getLootPoolItem(
        TokenType tokenType,
        uint256 index
    ) public view returns (address, uint256) {
        if (tokenType == TokenType.ERC721) {
            require(
                index < currentLootpool.erc721Items.length,
                "ERC721: Index out of bounds"
            );
            return (
                currentLootpool.erc721Items[index].contractAddress,
                currentLootpool.erc721Items[index].tokenId
            );
        } else if (tokenType == TokenType.ERC20) {
            require(
                index < currentLootpool.erc20Items.length,
                "ERC20: Index out of bounds"
            );
            return (
                currentLootpool.erc20Items[index].contractAddress,
                currentLootpool.erc20Items[index].amount
            );
        }
        revert("Invalid token type");
    }

    /**
     * @dev rescues erc721 tokens sent directly to vault
     */
    function rescueERC721(
        address token,
        uint256 tokenId
    ) public onlyApprovedOwner {
        IERC721(token).transferFrom(address(this), owner(), tokenId);
    }
}