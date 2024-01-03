// Sources flattened with hardhat v2.0.1 https://hardhat.org

// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol@v1.0.1

pragma solidity >=0.5.0;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File @uniswap/lib/contracts/libraries/AddressStringUtil.sol@v1.1.4

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

library AddressStringUtil {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr, uint len) pure internal returns (string memory) {
        require(len % 2 == 0 && len > 0 && len <= 40, "AddressStringUtil: INVALID_LEN");

        bytes memory s = new bytes(len);
        uint addrNum = uint(addr);
        for (uint i = 0; i < len / 2; i++) {
            // shift right and truncate all but the least significant byte to extract the byte at position 19-i
            uint8 b = uint8(addrNum >> (8 * (19 - i)));
            // first hex character is the most significant 4 bits
            uint8 hi = b >> 4;
            // second hex character is the least significant 4 bits
            uint8 lo = b - (hi << 4);
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    // hi and lo are only 4 bits and between 0 and 16
    // this method converts those values to the unicode/ascii code point for the hex representation
    // uses upper case for the characters
    function char(uint8 b) pure private returns (byte c) {
        if (b < 10) {
            return byte(b + 0x30);
        } else {
            return byte(b + 0x37);
        }
    }
}


// File @uniswap/lib/contracts/libraries/SafeERC20Namer.sol@v1.1.4


pragma solidity >=0.5.0;

// produces token descriptors from inconsistent or absent ERC20 symbol implementations that can return string or bytes32
// this library will always produce a string symbol to represent the token
library SafeERC20Namer {
    function bytes32ToString(bytes32 x) pure private returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    // assumes the data is in position 2
    function parseStringData(bytes memory b) pure private returns (string memory) {
        uint charCount = 0;
        // first parse the charCount out of the data
        for (uint i = 32; i < 64; i++) {
            charCount <<= 8;
            charCount += uint8(b[i]);
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint i = 0; i < charCount; i++) {
            bytesStringTrimmed[i] = b[i + 64];
        }

        return string(bytesStringTrimmed);
    }

    // uses a heuristic to produce a token name from the address
    // the heuristic returns the full hex of the address string in upper case
    function addressToName(address token) pure private returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 40);
    }

    // uses a heuristic to produce a token symbol from the address
    // the heuristic returns the first 6 hex of the address string in upper case
    function addressToSymbol(address token) pure private returns (string memory) {
        return AddressStringUtil.toAsciiString(token, 6);
    }

    // calls an external view token contract method that returns a symbol or name, and parses the output into a string
    function callAndParseStringReturn(address token, bytes4 selector) view private returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) internal view returns (string memory) {
        // 0x95d89b41 = bytes4(keccak256("symbol()"))
        string memory symbol = callAndParseStringReturn(token, 0x95d89b41);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) internal view returns (string memory) {
        // 0x06fdde03 = bytes4(keccak256("name()"))
        string memory name = callAndParseStringReturn(token, 0x06fdde03);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }
        return name;
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol@v3.0.0

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


// File @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol@v3.0.0

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol@v3.0.0

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol@v3.0.0

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}


// File @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol@v3.0.0

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}


// File contracts/v612/FlashArbitrageController.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


// import "./console.sol";


// import "./Ownable.sol";


// _________  ________ _____________________                                             
// \_   ___ \ \_____  \\______   \_   _____/                                             
// /    \  \/  /   |   \|       _/|    __)_                                              
// \     \____/    |    \    |   \|        \                                             
//  \______  /\_______  /____|_  /_______  /                                             
//         \/         \/       \/        \/                                              
// ___________.____       _____    _________ ___ ___                                     
// \_   _____/|    |     /  _  \  /   _____//   |   \                                    
//  |    __)  |    |    /  /_\  \ \_____  \/    ~    \                                   
//  |     \   |    |___/    |    \/        \    Y    /                                   
//  \___  /   |_______ \____|__  /_______  /\___|_  /                                    
//      \/            \/       \/        \/       \/                                     
//    _____ ____________________.________________________    _____    ___________________
//   /  _  \\______   \______   \   \__    ___/\______   \  /  _  \  /  _____/\_   _____/
//  /  /_\  \|       _/|    |  _/   | |    |    |       _/ /  /_\  \/   \  ___ |    __)_ 
// /    |    \    |   \|    |   \   | |    |    |    |   \/    |    \    \_\  \|        \
// \____|__  /____|_  /|______  /___| |____|    |____|_  /\____|__  /\______  /_______  /
//         \/       \/        \/                       \/         \/        \/        \/ 
//  Controller
//
// This contract checks for opportunities to gain profit for all of DEXs out there
// But especially the CORE ecosystem because this contract can tell another contrac to turn feeOff for the duration of its trades
// By arbitraging all existing pools, and transfering profits to FeeSplitter
// That will add rewards to specific pools to keep them at X% APY
// And add liquidity and subsequently burn the liquidity tokens after all pools reach this threashold
//
//      .edee...      .....       .eeec.   ..eee..
//    .d*"  """"*e..d*"""""**e..e*""  "*c.d""  ""*e.
//   z"           "$          $""       *F         **e.
//  z"             "c        d"          *.           "$.
// .F                        "            "            'F
// d                                                   J%
// 3         .                                        e"
// 4r       e"              .                        d"
//  $     .d"     .        .F             z ..zeeeeed"
//  "*beeeP"      P        d      e.      $**""    "
//      "*b.     Jbc.     z*%e.. .$**eeeeP"
//         "*beee* "$$eeed"  ^$$$""    "
//                  '$$.     .$$$c
//                   "$$.   e$$*$$c
//                    "$$..$$P" '$$r
//                     "$$$$"    "$$.           .d
//         z.          .$$$"      "$$.        .dP"
//         ^*e        e$$"         "$$.     .e$"
//           *b.    .$$P"           "$$.   z$"
//            "$c  e$$"              "$$.z$*"
//             ^*e$$P"                "$$$"
//               *$$                   "$$r
//               '$$F                 .$$P
//                $$$                z$$"
//                4$$               d$$b.
//                .$$%            .$$*"*$$e.
//             e$$$*"            z$$"    "*$$e.
//            4$$"              d$P"        "*$$e.
//            $P              .d$$$c           "*$$e..
//           d$"             z$$" *$b.            "*$L
//          4$"             e$P"   "*$c            ^$$
//          $"            .d$"       "$$.           ^$r
//         dP            z$$"         ^*$e.          "b
//        4$            e$P             "$$           "
//                     J$F               $$
//                     $$               .$F
//                    4$"               $P"
//                    $"               dP    kjRWG0tKD4A
//
// I'll have you know...
interface IFlashArbitrageExecutor {
    function getStrategyProfitInReturnToken(address[] memory pairs, uint256[] memory feeOnTransfers, bool[] memory token0Out) external view returns (uint256);
    function executeStrategy(uint256) external;
    // Strategy that self calculates best input but costs gas
    function executeStrategy(address[] memory pairs, uint256[] memory feeOnTransfers, bool[] memory token0Out, bool cBTCSupport) external;
    // strategy that does not calculate the best input meant for miners
    function executeStrategy(uint256 borrowAmt, address[] memory pairs, uint256[] memory feeOnTransfers, bool[] memory token0Out, bool cBTCSupport) external;

    function getOptimalInput(address[] memory pairs, uint256[] memory feeOnTransfers, bool[] memory token0Out) external view returns (uint256);
}


contract FlashArbitrageController is OwnableUpgradeSafe {
    using SafeMath for uint256;

    event StrategyAdded(string indexed name, uint256 indexed id, address[] pairs, bool feeOff, address indexed originator);

    struct Strategy {
        string strategyName;
        bool[] token0Out; // An array saying if token 0 should be out in this step
        address[] pairs; // Array of pair addresses
        uint256[] feeOnTransfers; //Array of fee on transfers 1% = 10
        bool cBTCSupport; // Should the algorithm check for cBTC and wrap/unwrap it
                        // Note not checking saves gas
        bool feeOff; // Allows for adding CORE strategies - where there is no fee on the executor
    }

    uint256 public revenueSplitFeeOffStrategy;
    uint256 public revenueSplitFeeOnStrategy;

    address public  distributor;
    IFlashArbitrageExecutor public executor;
    address public cBTC;
    address public CORE;
    address public wBTC;
    bool depreciated; // This contract can be upgraded to a new one
                      // But we don't want people to add new strategies if its depreciated
    uint8 MAX_STEPS_LEN; // This variable is responsible to minimsing risk of gas limit strategies being added
                        // Which would always have 0 gas cost because they could never complete
    Strategy[] public strategies;


    function initialize(address _executor, address _distributor) initializer public  {
        require(tx.origin == address(0x5A16552f59ea34E44ec81E58b3817833E9fD5436));
        cBTC = 0x7b5982dcAB054C377517759d0D2a3a5D02615AB8;
        CORE = 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7;
        wBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        distributor = _distributor; // we dont hard set it because its not live yet
                                    // So can't easily mock it in tests
        executor = IFlashArbitrageExecutor(_executor);
        revenueSplitFeeOffStrategy = 100; // 10%
        revenueSplitFeeOnStrategy = 650; // 65%
        MAX_STEPS_LEN = 20;
    }

    
    /////////////////
    //// ADMIN SETTERS
    //////////////////

    //In case executor needs to be updated
    function setExecutor(address _executor) onlyOwner public {
        executor = IFlashArbitrageExecutor(_executor);
    }

    //In case executor needs to be updated
    function setDistributor(address _distributor) onlyOwner public {
        distributor = _distributor;
    }

    function setMaxStrategySteps(uint8 _maxSteps) onlyOwner public {
        MAX_STEPS_LEN = _maxSteps;
    }

    function setDepreciated(bool _depreciated) onlyOwner public {
        depreciated = _depreciated;
    }

    function setFeeSplit(uint256 _revenueSplitFeeOffStrategy, uint256 _revenueSplitFeeOnStrategy) onlyOwner public {
        // We cap both fee splits to 20% max and 95% max
        // This means people calling feeOff strategies get max 20% revenue
        // And people calling feeOn strategies get max 95%
        require(revenueSplitFeeOffStrategy <= 200, "FA : 20% max fee for feeOff revenue split");
        require(revenueSplitFeeOnStrategy <= 950, "FA : 95% max fee for feeOff revenue split");
        revenueSplitFeeOffStrategy = _revenueSplitFeeOffStrategy;
        revenueSplitFeeOnStrategy = _revenueSplitFeeOnStrategy;
    }


    /////////////////
    //// Views for strategies
    //////////////////
    function getOptimalInput(uint256 strategyPID) public view returns (uint256) {
        Strategy memory currentStrategy = strategies[strategyPID];
        return executor.getOptimalInput(currentStrategy.pairs, currentStrategy.feeOnTransfers, currentStrategy.token0Out);
    }

    // Returns the current profit of strateg if it was executed
    // In return token - this means if you borrow CORE from CORe/cBTC pair
    // This profit would be denominated in cBTC
    // Since thats what you have to return 
    function strategyProfitInReturnToken(uint256 strategyID) public view returns (uint256 profit) {
        Strategy memory currentStrategy = strategies[strategyID];
        return executor.getStrategyProfitInReturnToken(currentStrategy.pairs, currentStrategy.feeOnTransfers, currentStrategy.token0Out);
    }


    // Returns information about the strategy
    function strategyInfo(uint256 strategyPID) public view returns (Strategy memory){
        return strategies[strategyPID];
    }

    function numberOfStrategies() public view returns (uint256) {
        return strategies.length;
    }



    ///////////////////
    //// Strategy execution
    //// And profit assurances
    //////////////////

    // Public function that executes a strategy
    // since its all a flash swap
    // the strategies can't lose money only gain
    // so its appropriate that they are public here
    // I don't think its possible that one of the strategies that is less profitable
    // takes away money from the more profitable one
    // Otherwise people would be able to do it anyway with their own contracts
    function executeStrategy(uint256 strategyPID) public {
        // function executeStrategy(address[] memory pairs, uint256[] memory feeOnTransfers, bool[] memory token0Out, bool cBTCSupport) external;
        require(!depreciated, "This Contract is depreciated");
        Strategy memory currentStrategy = strategies[strategyPID];

        executor.executeStrategy(currentStrategy.pairs, currentStrategy.feeOnTransfers, currentStrategy.token0Out, currentStrategy.cBTCSupport);

        // console.log("Executed Strategy");

        // Eg. Token 0 was out so profit token is token 1
        address profitToken = currentStrategy.token0Out[0] ? 
            IUniswapV2Pair(currentStrategy.pairs[0]).token1() 
                : 
            IUniswapV2Pair(currentStrategy.pairs[0]).token0();

        // console.log("Profit token", profitToken);

        uint256 profit = IERC20(profitToken).balanceOf(address(this));
        // console.log("Profit ", profit);

        // We split the profit based on the strategy
        if(currentStrategy.feeOff) {
            safeTransfer(profitToken, msg.sender, profit.mul(revenueSplitFeeOffStrategy).div(1000));
        }
        else {
            safeTransfer(profitToken, msg.sender, profit.mul(revenueSplitFeeOnStrategy).div(1000));
        }
        // console.log("Send revenue split now have ", IERC20(profitToken).balanceOf(address(this)) );

        safeTransfer(profitToken, distributor, IERC20(profitToken).balanceOf(address(this)));

    }


    ///////////////////
    //// Adding strategies
    //////////////////


    // Normal add without Fee Ontrasnfer being specified
    function addNewStrategy(bool borrowToken0, address[] memory pairs) public returns (uint256 strategyID) {

        uint256[] memory feeOnTransfers = new uint256[](pairs.length);
        strategyID = addNewStrategyWithFeeOnTransferTokens(borrowToken0, pairs, feeOnTransfers);

    }

    //Adding strategy with fee on transfer support
    function addNewStrategyWithFeeOnTransferTokens(bool borrowToken0, address[] memory pairs, uint256[] memory feeOnTransfers) public returns (uint256 strategyID) {
        require(!depreciated, "This Contract is depreciated");
        require(pairs.length <= MAX_STEPS_LEN, "FA Controller - too many steps");
        require(pairs.length > 1, "FA Controller - Specifying one pair is not arbitage");
        require(pairs.length == feeOnTransfers.length, "FA Controller: Malformed Input -  pairs and feeontransfers should equal");
        bool[] memory token0Out = new bool[](pairs.length);
        // First token out is the same as borrowTokenOut
        token0Out[0] = borrowToken0;

        address token0 = IUniswapV2Pair(pairs[0]).token0();
        address token1 = IUniswapV2Pair(pairs[0]).token1();
        if(msg.sender != owner()) {
            require(token0 != CORE && token1 != CORE, "FA Controller: CORE strategies can be only added by an admin");
        }        
        
        bool cBTCSupport;
        // We turn on cbtc support if any of the borrow token pair has cbtc
        if(token0 == cBTC || token1 == cBTC) cBTCSupport = true;

        // Establish the first token out
        address lastToken = borrowToken0 ? token0 : token1;
        // console.log("Borrowing Token", lastToken);

       
        string memory strategyName = append(
            SafeERC20Namer.tokenSymbol(lastToken),
            " price too low. In ", 
            SafeERC20Namer.tokenSymbol(token0), "/", 
            SafeERC20Namer.tokenSymbol(token1), " pair");

        // console.log(strategyName);

        // Loop over all other pairs
        for (uint256 i = 1; i < token0Out.length; i++) {

            address token0 = IUniswapV2Pair(pairs[i]).token0();
            address token1 = IUniswapV2Pair(pairs[i]).token1();

            if(msg.sender != owner()) {
                require(token0 != CORE && token1 != CORE, "FA Controller: CORE strategies can be only added by an admin");
            }

            // console.log("Last token is", lastToken);
            // console.log("pair is",pairs[i]);
  
            
            // We turn on cbtc support if any of the pairs have cbts
            if(lastToken == cBTC || lastToken == wBTC){       
                require(token0 == cBTC || token1 == cBTC || token0 == wBTC || token1 == wBTC,
                    "FA Controller: Malformed Input - pair does not contain previous token");

            } else{
                // We check if the token is in the next pair
                // If its not then its a wrong input
                // console.log("Last token", lastToken);
                require(token0 == lastToken || token1 == lastToken, "FA Controller: Malformed Input - pair does not contain previous token");

            }




            // If last token is cBTC
            // And the this pair has wBTC in it
            // Then we should have the last token as wBTC
            if(lastToken == cBTC) {
                // console.log("Flipping here");
                cBTCSupport = true;
                // If last token is cBTC and this pair has wBTC and no cBTC
                // Then we are inputting wBTC after unwrapping
                 if(token0 == wBTC || token1 == wBTC && token0 != cBTC && token1 != cBTC){
                     
                     // The token we take out here is opposite of wbtc
                     // Token 0 is out if wBTC is token1
                     // Because we are inputting wBTC
                     token0Out[i] = wBTC == token1;
                     lastToken = wBTC == token1 ? token0 : token1;
                 }
            }

            // If last token is wBTC
            // And cbtc is in this pair
            // And wbtc isn't in this pair
            // Then we wrapped cBTC
             else if(lastToken == wBTC && token0 == cBTC || token1 == cBTC && token0 != wBTC && token1 != wBTC){
                // explained above with cbtc
                cBTCSupport = true;
                token0Out[i] = cBTC == token1;
                lastToken = cBTC == token1 ? token0 : token1;
                // console.log("Token0 out from last wBTC");
            }
            //Default case with no cBTC support
            else {
                // If token 0 is the token we are inputting, the last one
                // Then we take the opposite here
                token0Out[i] = token1 == lastToken;

                // We take the opposite
                // So if we input token1
                // Then token0 is out
                lastToken = token0 == lastToken ? token1 : token0;
                // console.log("Basic branch last token is ", lastToken);
                // console.log("Basic branch last token1 is ", token1);
                // console.log("Basic branch last token0 is ", token0);

                // console.log("Token0 out from basic branch");

            }
          


        //    console.log("Last token is", lastToken);
        
        }
        
        // address[] memory pairs, uint256[] memory feeOnTransfers, bool[] memory token0Out, bool cBTCSupport
        strategies.push(
            Strategy({
                strategyName : strategyName,
                token0Out : token0Out,
                pairs : pairs,
                feeOnTransfers : feeOnTransfers,
                cBTCSupport : cBTCSupport,
                feeOff : msg.sender == owner()
            })
        );

        strategyID = strategies.length;

        emit StrategyAdded(strategyName, strategyID, pairs, msg.sender == owner(), msg.sender);
    }

  
    ///////////////////
    //// Helper functions
    //////////////////
    function sendETH(address payable to, uint256 amt) internal {
        // console.log("I'm transfering ETH", amt/1e18, to);
        // throw exception on failure
        to.transfer(amt);
    }

    function safeTransfer(address token, address to, uint256 value) internal {
            // bytes4(keccak256(bytes('transfer(address,uint256)')));
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'FA Controller: TRANSFER_FAILED');
    }

    function getTokenSafeName(address token) public view returns (string memory) {
        return SafeERC20Namer.tokenSymbol(token);
    }

    // A function that lets owner remove any tokens from this addrss
    // note this address shoudn't hold any tokens
    // And if it does that means someting already went wrong or someone send them to this address
    function rescueTokens(address token, uint256 amt) public onlyOwner {
        IERC20(token).transfer(owner(), amt);
    }

    function rescueETH(uint256 amt) public {
        sendETH(0xd5b47B80668840e7164C1D1d81aF8a9d9727B421, amt);
    }

    // appends two strings together
    function append(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b,c,d,e,f));
    }


    ///////////////////
    //// Additional functions
    //////////////////

    // This function is for people who do not want to reveal their strategies
    // Note we can do this function because executor requires this contract to be a caller when doing feeoff stratgies
    function skimToken(address _token) public {
        IERC20 token = IERC20(_token);
        uint256 balToken = token.balanceOf(address(this));
        safeTransfer(_token, msg.sender, balToken.mul(revenueSplitFeeOffStrategy).div(1000));
        safeTransfer(_token, distributor, token.balanceOf(address(this)));
    }


}