// SPDX-License-Identifier: MIT
// File: bitcornswapbackup/interfaces/IUniswapV2Callee.sol

pragma solidity ^0.8.20;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: bitcornswapbackup/interfaces/IERC20.sol

pragma solidity ^0.8.20;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: bitcornswapbackup/libraries/Math.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}
// File: bitcornswapbackup/interfaces/IStruct.sol


pragma solidity ^0.8.0;

interface IStruct {
// Declare the SwapResults struct
struct SwapResults {
    address ref;
    address feeToken;
    uint256 amtFee;
    uint256 finalAmount0Out;
    uint256 finalAmount1Out;
}
}

// File: bitcornswapbackup/interfaces/IUniswapV2ERC20.sol

pragma solidity ^0.8.20;

interface IUniswapV2ERC20 {
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
}

// File: bitcornswapbackup/UniswapV2ERC20.sol

pragma solidity ^0.8.20;


contract UniswapV2ERC20 is IUniswapV2ERC20 {

    string public constant name = 'Corn LP';
    string public constant symbol = 'Corn-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() {
        uint chainId;
        chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply +=value ;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            uint remaining = allowance[from][msg.sender] - (value);
            allowance[from][msg.sender] = remaining;
            emit Approval(from, msg.sender, remaining);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'CornswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CornswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: bitcornswapbackup/interfaces/ICornPair.sol

pragma solidity ^0.8.20;



interface ICornPair is IUniswapV2ERC20, IStruct {

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
    event DiscountSwap(
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function kLast() external view returns (uint);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint256 refamt, address referrer) external;
    function discountSwap(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint256 refamt, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: bitcornswapbackup/interfaces/ICornFactory.sol

pragma solidity ^0.8.20;

interface ICornFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feePercentOwner() external view returns (address);
    function setStableOwner() external view returns (address);
    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function feeInfo() external view returns (uint _ownerFeeShare, address _feeTo);
    function gwassie() external view returns (address);
}

// File: bitcornswapbackup/CornPairV2.sol

pragma solidity ^0.8.20;







contract CornPair is ICornPair, UniswapV2ERC20 {

  uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
  bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  address public factory;
  address public token0;
  address public token1;

  bool public initialized;

  uint public constant FEE_DENOMINATOR = 100000;
  uint public constant MAX_FEE_PERCENT = 2000; // = 2%

  uint112 private reserve0;           // uses single storage slot, accessible via getReserves
  uint112 private reserve1;           // uses single storage slot, accessible via getReserves
  uint16 public token0FeePercent = 300; // default = 0.3%  // uses single storage slot, accessible via getReserves
  uint16 public token1FeePercent = 300; // default = 0.3%  // uses single storage slot, accessible via getReserves

  uint public precisionMultiplier0;
  uint public precisionMultiplier1;

  uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

  bool public stableSwap; // if set to true, defines pair type as stable
  bool public pairTypeImmutable; // if set to true, stableSwap states cannot be updated anymore

  uint private unlocked = 1;

  modifier onlyGold(){
    require(IERC20(gwassie()).balanceOf(msg.sender) >= (1 * 1e18));
    _;
  }
  modifier lock() {
    require(unlocked == 1, 'CornPair: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }
  
  function gwassie() public view returns (address){
    return ICornFactory(factory).gwassie();
  }

  function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent) {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _token0FeePercent = token0FeePercent;
    _token1FeePercent = token1FeePercent;
  }

  function _safeTransfer(address token, address to, uint value) private {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'CornPair: TRANSFER_FAILED');
  }

  event DrainWrongToken(address indexed token, address to);
  event FeePercentUpdated(uint16 token0FeePercent, uint16 token1FeePercent);
  event SetStableSwap(bool prevStableSwap, bool stableSwap);
  event SetPairTypeImmutable();
  event Skim();

  constructor() {
    factory = msg.sender;
  }

  // called once by the factory at time of deployment
  function initialize(address _token0, address _token1) external {
    require(msg.sender == factory && !initialized, 'CornPair: FORBIDDEN');
    // sufficient check
    token0 = _token0;
    token1 = _token1;

    precisionMultiplier0 = 10 ** uint(IERC20(_token0).decimals());
    precisionMultiplier1 = 10 ** uint(IERC20(_token1).decimals());

    initialized = true;
  }

  /**
  * @dev Updates the swap fees percent
  *
  * Can only be called by the factory's feeAmountOwner
  */
  function setFeePercent(uint16 newToken0FeePercent, uint16 newToken1FeePercent) external lock {
    require(msg.sender == ICornFactory(factory).feePercentOwner(), "CornPair: only factory's feeAmountOwner");
    require(newToken0FeePercent <= MAX_FEE_PERCENT && newToken1FeePercent <= MAX_FEE_PERCENT, "CornPair: feePercent mustn't exceed the maximum");
    require(newToken0FeePercent > 0 && newToken1FeePercent > 0, "CornPair: feePercent mustn't exceed the minimum");
    token0FeePercent = newToken0FeePercent;
    token1FeePercent = newToken1FeePercent;
    emit FeePercentUpdated(newToken0FeePercent, newToken1FeePercent);
  }

  function setStableSwap(bool stable, uint112 expectedReserve0, uint112 expectedReserve1) external lock {
    require(msg.sender == ICornFactory(factory).setStableOwner(), "CornPair: only factory's setStableOwner");
    require(!pairTypeImmutable, "CornPair: immutable");

    require(stable != stableSwap, "CornPair: no update");
    require(expectedReserve0 == reserve0 && expectedReserve1 == reserve1, "CornPair: failed");

    bool feeOn = _mintFee(reserve0, reserve1);

    emit SetStableSwap(stableSwap, stable);
    stableSwap = stable;
    kLast = (stable && feeOn) ? _k(uint(reserve0), uint(reserve1)) : 0;
  }

  function setPairTypeImmutable() external lock {
    require(msg.sender == ICornFactory(factory).owner(), "CornPair: only factory's owner");
    require(!pairTypeImmutable, "CornPair: already immutable");

    pairTypeImmutable = true;
    emit SetPairTypeImmutable();
  }

  // update reserves
  function _update(uint balance0, uint balance1) private {
    require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'CornPair: OVERFLOW');

    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    emit Sync(uint112(balance0), uint112(balance1));
  }

  // if fee is on, mint liquidity equivalent to "factory.ownerFeeShare()" of the growth in sqrt(k)
  // only for uni configuration
  function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
    if(stableSwap) return false;

    (uint ownerFeeShare, address feeTo) = ICornFactory(factory).feeInfo();
    feeOn = feeTo != address(0);
    uint _kLast = kLast;
    // gas savings
    if (feeOn) {
      if (_kLast != 0) {
        uint rootK = Math.sqrt(_k(uint(_reserve0), uint(_reserve1)));
        uint rootKLast = Math.sqrt(_kLast);
        if (rootK > rootKLast) {
          uint d = ((FEE_DENOMINATOR * 100) / ownerFeeShare) - 100;
            uint numerator = totalSupply * (rootK - rootKLast) * 100;
            uint denominator = (rootK * d) + (rootKLast * 100);
            uint liquidity = numerator / denominator;
            if (liquidity > 0) _mint(feeTo, liquidity);
        }
      }
    } else if (_kLast != 0) {
      kLast = 0;
    }
  }

  // this low-level function should be called from a contract which performs important safety checks
  function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1,,) = getReserves();
    // gas savings
    uint balance0 = IERC20(token0).balanceOf(address(this));
    uint balance1 = IERC20(token1).balanceOf(address(this));
    uint amount0 = balance0 - (_reserve0);
    uint amount1 = balance1 - (_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply;
    // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
      liquidity = Math.sqrt(amount0 * amount1) - (MINIMUM_LIQUIDITY);
      _mint(address(0), MINIMUM_LIQUIDITY);
      // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
      liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
    }
    require(liquidity > 0, 'CornPair: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1);
    if (feeOn) kLast = _k(uint(reserve0), uint(reserve1));
    // reserve0 and reserve1 are up-to-date
    emit Mint(msg.sender, amount0, amount1);
  }

  // this low-level function should be called from a contract which performs important safety checks
  function burn(address to) external lock returns (uint amount0, uint amount1) {
    (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
    address _token0 = token0; // gas savings
    address _token1 = token1; // gas savings
    uint balance0 = IERC20(_token0).balanceOf(address(this));
    uint balance1 = IERC20(_token1).balanceOf(address(this));
    uint liquidity = balanceOf[address(this)];

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
    amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
    require(amount0 > 0 && amount1 > 0, 'CornPair: INSUFFICIENT_LIQUIDITY_BURNED');
    _burn(address(this), liquidity);
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);
    balance0 = IERC20(_token0).balanceOf(address(this));
    balance1 = IERC20(_token1).balanceOf(address(this));

    _update(balance0, balance1);
    if (feeOn) kLast = _k(uint(reserve0), uint(reserve1)); // reserve0 and reserve1 are up-to-date
    emit Burn(msg.sender, amount0, amount1, to);
  }

  struct TokensData {
    address token0;
    address token1;
    uint amount0Out;
    uint amount1Out;
    uint balance0;
    uint balance1;
    uint remainingFee0;
    uint remainingFee1;
  }

  // this low-level function should be called from a contract which performs important safety checks
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
    TokensData memory tokensData = TokensData({
      token0: token0,
      token1: token1,
      amount0Out: amount0Out,
      amount1Out: amount1Out,
      balance0: 0,
      balance1: 0,
      remainingFee0: 0,
      remainingFee1: 0
    });
    _swap(tokensData, to, data, 0, address(0));
  }

    // this low-level function should be called from a contract which performs important safety checks
  function discountSwap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external onlyGold {
    TokensData memory tokensData = TokensData({
      token0: token0,
      token1: token1,
      amount0Out: amount0Out,
      amount1Out: amount1Out,
      balance0: 0,
      balance1: 0,
      remainingFee0: 0,
      remainingFee1: 0
    });
    _swap(tokensData, to, data, 0, address(0));
  }


  // this low-level function should be called from a contract which performs important safety checks
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint256 refamt, address referrer) external {
    TokensData memory tokensData = TokensData({
      token0: token0,
      token1: token1,
      amount0Out: amount0Out,
      amount1Out: amount1Out,
      balance0: 0,
      balance1: 0,
      remainingFee0: 0,
      remainingFee1: 0
    });
    _swap(tokensData, to, data, refamt, referrer);
  }

    // this low-level function should be called from a contract which performs important safety checks
  function discountSwap(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint256 refamt, address referrer) external onlyGold {
    TokensData memory tokensData = TokensData({
      token0: token0,
      token1: token1,
      amount0Out: amount0Out,
      amount1Out: amount1Out,
      balance0: 0,
      balance1: 0,
      remainingFee0: 0,
      remainingFee1: 0
    });
    _swap(tokensData, to, data, refamt, referrer);
  }


  function _swap(TokensData memory tokensData, address to, bytes memory data, uint256 refamt, address referrer) internal lock {
    require(tokensData.amount0Out > 0 || tokensData.amount1Out > 0, 'CornPair: INSUFFICIENT_OUTPUT_AMOUNT');

    (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent) = getReserves();
    require(tokensData.amount0Out < _reserve0 && tokensData.amount1Out < _reserve1, 'CornPair: INSUFFICIENT_LIQUIDITY');


    {
      require(to != tokensData.token0 && to != tokensData.token1, 'CornPair: INVALID_TO');
      // optimistically transfer tokens
      if (tokensData.amount0Out > 0) _safeTransfer(tokensData.token0, to, tokensData.amount0Out);
      // optimistically transfer tokens
      if (tokensData.amount1Out > 0) _safeTransfer(tokensData.token1, to, tokensData.amount1Out);
      if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, tokensData.amount0Out, tokensData.amount1Out, data);
      tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
      tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
    }

    uint amount0In = tokensData.balance0 > _reserve0 - tokensData.amount0Out ? tokensData.balance0 - (_reserve0 - tokensData.amount0Out) : 0;
    uint amount1In = tokensData.balance1 > _reserve1 - tokensData.amount1Out ? tokensData.balance1 - (_reserve1 - tokensData.amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'CornPair: INSUFFICIENT_INPUT_AMOUNT');

    tokensData.remainingFee0 = (amount0In * (_token0FeePercent)) / FEE_DENOMINATOR;
    tokensData.remainingFee1 = (amount1In * (_token1FeePercent)) / FEE_DENOMINATOR;

    {// scope for referer/stable fees management
      uint fee = 0;
      uint referrerInputFeeShare = referrer != address(0) ? refamt : 0;
      if (referrerInputFeeShare > 0) {
        if (amount0In > 0) {
            fee = (amount0In * referrerInputFeeShare * tokensData.remainingFee0) / (FEE_DENOMINATOR ** 2);
            tokensData.remainingFee0 -= fee;
            _safeTransfer(tokensData.token0, referrer, ((fee * 200) / 300));
            _safeTransfer(tokensData.token0, ICornFactory(factory).owner(), ((fee * 100) / 300));
        }
        if (amount1In > 0) {
            fee = (amount1In * referrerInputFeeShare * tokensData.remainingFee1) / (FEE_DENOMINATOR ** 2);
            tokensData.remainingFee1 -= fee;
            _safeTransfer(tokensData.token1, referrer, ((fee * 200) / 300));
            _safeTransfer(tokensData.token1, ICornFactory(factory).owner(), ((fee * 100) / 300));
        }
      }

      if(stableSwap){
        (uint ownerFeeShare, address feeTo) = ICornFactory(factory).feeInfo();
        if(feeTo != address(0)) {
            ownerFeeShare = (FEE_DENOMINATOR - referrerInputFeeShare) * ownerFeeShare;
            if (amount0In > 0) {
                fee = (amount0In * ownerFeeShare * tokensData.remainingFee0) / (FEE_DENOMINATOR ** 3);
                tokensData.remainingFee0 -= fee;
                _safeTransfer(tokensData.token0, feeTo, fee);
          }
          if (amount1In > 0) {
                fee = (amount1In * ownerFeeShare * tokensData.remainingFee1) / (FEE_DENOMINATOR ** 3);
                tokensData.remainingFee1 -= fee;
                _safeTransfer(tokensData.token1, feeTo, fee);
          }
        }
      }
      // readjust tokens balance
      if (amount0In > 0) tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
      if (amount1In > 0) tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
    }
    {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
      uint balance0Adjusted = tokensData.balance0 - (tokensData.remainingFee0);
      uint balance1Adjusted = tokensData.balance1 - (tokensData.remainingFee1);
      require(_k(balance0Adjusted, balance1Adjusted) >= _k(uint(_reserve0), uint(_reserve1)), 'CornPair: K');
    }
    _update(tokensData.balance0, tokensData.balance1);
    //push emit to own function to avoid stack too deep
    _emitter(amount0In, amount1In, tokensData.amount0Out, tokensData.amount1Out, to);
  }

  function _emitter(uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address to) internal {
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }

  function _k(uint balance0, uint balance1) internal view returns (uint) {
    if (stableSwap) {
      uint _x = (balance0 * (1e18)) / precisionMultiplier0;
      uint _y = (balance1 * (1e18)) / precisionMultiplier1;
      uint _a = (_x * _y) / 1e18;
      uint _b = ((_x * (_x)) / 1e18) +((_y*_y) / 1e18);
      return  (_a *_b) / 1e18; // x3y+y3x >= k
    }
    return balance0 * balance1;
  }

  function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
    for (uint i = 0; i < 255; i++) {
      uint y_prev = y;
      uint k = _f(x0, y);
      if (k < xy) {
        uint dy = (xy - k) * 1e18 / _d(x0, y);
        y = y + dy;
      } else {
        uint dy = (k - xy) * 1e18 / _d(x0, y);
        y = y - dy;
      }
      if (y > y_prev) {
        if (y - y_prev <= 1) {
          return y;
        }
      } else {
        if (y_prev - y <= 1) {
          return y;
        }
      }
    }
    return y;
  }

  function _f(uint x0, uint y) internal pure returns (uint) {
    return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
  }

  function _d(uint x0, uint y) internal pure returns (uint) {
    return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
  }

  function getAmountOut(uint amountIn, address tokenIn) external view returns (uint) {
    uint16 feePercent = tokenIn == token0 ? token0FeePercent : token1FeePercent;
    return _getAmountOut(amountIn, tokenIn, uint(reserve0), uint(reserve1), feePercent);
  }

  function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, uint feePercent) internal view returns (uint) {
    if (stableSwap) {
      amountIn = amountIn - ((amountIn * feePercent) / FEE_DENOMINATOR); // remove fee from amount received
      uint xy = _k(_reserve0, _reserve1);
      _reserve0 = _reserve0 * 1e18 / precisionMultiplier0;
      _reserve1 = _reserve1 * 1e18 / precisionMultiplier1;

      (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      amountIn = tokenIn == token0 ? amountIn * 1e18 / precisionMultiplier0 : amountIn * 1e18 / precisionMultiplier1;
      uint y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
      return y * (tokenIn == token0 ? precisionMultiplier1 : precisionMultiplier0) / 1e18;

    } else {
      (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      amountIn = amountIn * (FEE_DENOMINATOR - feePercent);
      return (amountIn * reserveB) / ((reserveA * FEE_DENOMINATOR) + (amountIn));
    }
  }

  // force balances to match reserves
  function skim(address to) external lock {
    address _token0 = token0;
    // gas savings
    address _token1 = token1;
    // gas savings
    _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) -  reserve0);
    _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    emit Skim();
  }

  // force reserves to match balances
  function sync() external lock {
    uint token0Balance = IERC20(token0).balanceOf(address(this));
    uint token1Balance = IERC20(token1).balanceOf(address(this));
    require(token0Balance != 0 && token1Balance != 0, "CornPair: liquidity ratio not initialized");
    _update(token0Balance, token1Balance);
  }

  /**
  * @dev Allow to recover token sent here by mistake
  *
  * Can only be called by factory's owner
  */
  function drainWrongToken(address token, address to) external lock {
    require(msg.sender == ICornFactory(factory).owner(), "CornPair: only factory's owner");
    require(token != token0 && token != token1, "CornPair: invalid token");
    _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    emit DrainWrongToken(token, to);
  }

function _discountSwap(TokensData memory tokensData, address to, bytes memory data, uint256 refamt, address referrer) internal lock {
    require(tokensData.amount0Out > 0 || tokensData.amount1Out > 0, 'CornPair: INSUFFICIENT_OUTPUT_AMOUNT');

    (uint112 _reserve0, uint112 _reserve1, ,) = getReserves();
    require(tokensData.amount0Out < _reserve0 && tokensData.amount1Out < _reserve1, 'CornPair: INSUFFICIENT_LIQUIDITY');

    {
      require(to != tokensData.token0 && to != tokensData.token1, 'CornPair: INVALID_TO');
      // optimistically transfer tokens
      if (tokensData.amount0Out > 0) _safeTransfer(tokensData.token0, to, tokensData.amount0Out);
      // optimistically transfer tokens
      if (tokensData.amount1Out > 0) _safeTransfer(tokensData.token1, to, tokensData.amount1Out);
      if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, tokensData.amount0Out, tokensData.amount1Out, data);
      tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
      tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
    }

    uint amount0In = tokensData.balance0 > _reserve0 - tokensData.amount0Out ? tokensData.balance0 - (_reserve0 - tokensData.amount0Out) : 0;
    uint amount1In = tokensData.balance1 > _reserve1 - tokensData.amount1Out ? tokensData.balance1 - (_reserve1 - tokensData.amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'CornPair: INSUFFICIENT_INPUT_AMOUNT');

    tokensData.remainingFee0 = 0;
    tokensData.remainingFee1 = 0;

    {// scope for referer/stable fees management
      uint fee = 0;
      uint referrerInputFeeShare = referrer != address(0) ? refamt : 0;
      if (referrerInputFeeShare > 0) {
        if (amount0In > 0) {
            fee = (amount0In * referrerInputFeeShare * tokensData.remainingFee0) / (FEE_DENOMINATOR ** 2);
            tokensData.remainingFee0 -= fee;
            _safeTransfer(tokensData.token0, referrer, ((fee * 200) / 300));
            _safeTransfer(tokensData.token0, ICornFactory(factory).owner(), ((fee * 100) / 300));
        }
        if (amount1In > 0) {
            fee = (amount1In * referrerInputFeeShare * tokensData.remainingFee1) / (FEE_DENOMINATOR ** 2);
            tokensData.remainingFee1 -= fee;
            _safeTransfer(tokensData.token1, referrer, ((fee * 200) / 300));
            _safeTransfer(tokensData.token1, ICornFactory(factory).owner(), ((fee * 100) / 300));
        }
      }

      if(stableSwap){
        (uint ownerFeeShare, address feeTo) = ICornFactory(factory).feeInfo();
        if(feeTo != address(0)) {
            ownerFeeShare = (FEE_DENOMINATOR - referrerInputFeeShare) * ownerFeeShare;
            if (amount0In > 0) {
                fee = 0;
                tokensData.remainingFee0 -= fee;
          }
          if (amount1In > 0) {
                fee = 0;
                tokensData.remainingFee1 -= fee;
          }
        }
      }
      // readjust tokens balance
      if (amount0In > 0) tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
      if (amount1In > 0) tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
    }
    {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
      uint balance0Adjusted = tokensData.balance0 - (tokensData.remainingFee0);
      uint balance1Adjusted = tokensData.balance1 - (tokensData.remainingFee1);
      require(_k(balance0Adjusted, balance1Adjusted) >= _k(uint(_reserve0), uint(_reserve1)), 'CornPair: K');
    }
    _update(tokensData.balance0, tokensData.balance1);
    emit DiscountSwap(msg.sender, amount0In, amount1In, tokensData.amount0Out, tokensData.amount1Out, to);
  }
}
// File: bitcornswapbackup/CornFactoryV2.sol

pragma solidity ^0.8.20;



contract CornFactory is ICornFactory {
    address public owner;
    address public feePercentOwner;
    address public setStableOwner;
    address public feeTo;
    address public gwassie;

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(CornPair).creationCode));

    uint public constant OWNER_FEE_SHARE_MAX = 100000; // 100%
    uint public ownerFeeShare = 50000; // default value = 50%

    uint public constant REFERER_FEE_SHARE_MAX = 20000; // 20%

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event FeeToTransferred(address indexed prevFeeTo, address indexed newFeeTo);
    event OwnerFeeShareUpdated(uint prevOwnerFeeShare, uint ownerFeeShare);
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event FeePercentOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event SetStableOwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    constructor(address feeTo_) {
        owner = msg.sender;
        feePercentOwner = msg.sender;
        setStableOwner = msg.sender;
        feeTo = feeTo_;

        emit OwnershipTransferred(address(0), msg.sender);
        emit FeePercentOwnershipTransferred(address(0), msg.sender);
        emit SetStableOwnershipTransferred(address(0), msg.sender);
        emit FeeToTransferred(address(0), feeTo_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "CornFactory: caller is not the owner");
        _;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'CornFactory: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'CornFactory: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'CornFactory: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(CornPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(pair != address(0), "CornFactory: FAILED");
        CornPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "CornFactory: zero address");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    function setFeePercentOwner(address _feePercentOwner) external onlyOwner {
        require(_feePercentOwner != address(0), "CornFactory: zero address");
        emit FeePercentOwnershipTransferred(feePercentOwner, _feePercentOwner);
        feePercentOwner = _feePercentOwner;
    }

    function setSetStableOwner(address _setStableOwner) external {
        require(msg.sender == setStableOwner, "CornFactory: not setStableOwner");
        require(_setStableOwner != address(0), "CornFactory: zero address");
        emit SetStableOwnershipTransferred(setStableOwner, _setStableOwner);
        setStableOwner = _setStableOwner;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        emit FeeToTransferred(feeTo, _feeTo);
        feeTo = _feeTo;
    }

    /**
     * @dev Updates the share of fees attributed to the owner
     *
     * Must only be called by owner
     */
    function setOwnerFeeShare(uint newOwnerFeeShare) external onlyOwner {
        require(newOwnerFeeShare > 0, "CornFactory: ownerFeeShare mustn't exceed minimum");
        require(newOwnerFeeShare <= OWNER_FEE_SHARE_MAX, "CornFactory: ownerFeeShare mustn't exceed maximum");
        emit OwnerFeeShareUpdated(ownerFeeShare, newOwnerFeeShare);
        ownerFeeShare = newOwnerFeeShare;
    }

    function feeInfo() external view returns (uint _ownerFeeShare, address _feeTo) {
        _ownerFeeShare = ownerFeeShare;
        _feeTo = feeTo;
    }
}