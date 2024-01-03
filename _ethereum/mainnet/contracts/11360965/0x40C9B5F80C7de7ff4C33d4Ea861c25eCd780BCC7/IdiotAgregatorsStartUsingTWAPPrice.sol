// Sources flattened with hardhat v2.0.1 https://hardhat.org

// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol@v1.0.1
// SPDX-License-Identifier: JOE-MAMA
// COPYRIGHT Joe Mama

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


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol@v1.0.1

pragma solidity >=0.5.0;

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


// File @uniswap/v2-periphery/contracts/interfaces/IWETH.sol@v1.1.0-beta.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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


// File contracts/v612/DildoPrinter.sol

pragma solidity 0.6.12;




// import "./console.sol";

contract IdiotAgregatorsStartUsingTWAPPrice {
    using SafeMath for uint256;

    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory public constant uniFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    constructor () public {
        //shuup compiler lol
    }

    fallback() external payable {
        if(msg.sender != address(WETH)) revert();
    }



    function printDildoUpAndRefundRest(address forToken, uint256 timesCurrentPrice) public payable {
        require(msg.value > 0, "More money pls");
        require(forToken != 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7, "Not a shitcoin");
        require(timesCurrentPrice > 0, "Times higher pls");
        address pairAddy = uniFactory.getPair(address(WETH), forToken);
        require(pairAddy != address(0), "No pair with eth bro");
        WETH.deposit{value : msg.value}();
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddy);
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();

        // We want to get shitcoin out
        uint256 transferWETHAmt;
        if(token0 == address(WETH)) {
            // Reserve0 is weth
            // So we want to get token1
                                              // amountOut, reserveIn , reserveout
            uint256 getAmountInWETHFor1UnitOfToken = getAmountIn(1, reserve0, reserve1);
            transferWETHAmt = getAmountInWETHFor1UnitOfToken*timesCurrentPrice;
            WETH.transfer(address(pair),transferWETHAmt);
            pair.swap(0, 1, msg.sender, "");


        } else {
            uint256 getAmountInWETHFor1UnitOfToken = getAmountIn(1, reserve1, reserve0);
            transferWETHAmt = getAmountInWETHFor1UnitOfToken*timesCurrentPrice;
            WETH.transfer(address(pair), transferWETHAmt);
            pair.swap(1, 0, msg.sender, "");

        }
        // console.log("Bought for ",transferWETHAmt);
        WETH.withdraw(msg.value.sub(transferWETHAmt));
        (bool success,) = msg.sender.call.value(address(this).balance)("");
    }

    function printDildoDownAndRefundRest(address forToken, uint256 timesLowerCurrentPrice) public payable {
        require(msg.value > 0, "More money pls");
        require(forToken != 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7, "Not a shitcoin");
        require(timesLowerCurrentPrice > 0, "Times higher pls");
        address pairAddy = uniFactory.getPair(address(WETH), forToken);
        require(pairAddy != address(0), "No pair with eth bro");
        WETH.deposit{value : msg.value}();
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddy);
        address token0 = pair.token0();
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 transferWETHAmt;

        if(token0 == address(WETH)) { 
            /// Reserve0 is weth                          // amountOut, reserveIn , reserveout
            uint256 getAmountCoinsNeededToBuy1WETHUnit = getAmountIn(1, reserve1, reserve0);
            if(getAmountCoinsNeededToBuy1WETHUnit == 0) getAmountCoinsNeededToBuy1WETHUnit = 1;

            // We add 10% for buffer
            uint256 getAmountCoinsNeededToBuy1WETHUnitAdjusted = ((getAmountCoinsNeededToBuy1WETHUnit * 110) / 100) * timesLowerCurrentPrice;
                                                             // amountOut, reserveIn , reserveout
            transferWETHAmt = getAmountIn(getAmountCoinsNeededToBuy1WETHUnitAdjusted, reserve0, reserve1);
            WETH.transfer(address(pair), transferWETHAmt);
            // Get coin
            pair.swap(0, getAmountCoinsNeededToBuy1WETHUnitAdjusted, address(this), "");
            IERC20(forToken).transfer(address(pair), getAmountCoinsNeededToBuy1WETHUnitAdjusted);
            pair.swap(1, 0 , msg.sender, "");

        } else {
            /// Reserve1 is weth                          // amountOut, reserveIn , reserveout
            uint256 getAmountCoinsNeededToBuy1WETHUnit = getAmountIn(1, reserve0, reserve1);
            if(getAmountCoinsNeededToBuy1WETHUnit == 0) getAmountCoinsNeededToBuy1WETHUnit = 1;
            // We add 10% for buffer
            uint256 getAmountCoinsNeededToBuy1WETHUnitAdjusted = ((getAmountCoinsNeededToBuy1WETHUnit * 150) / 100) * timesLowerCurrentPrice;
                                                             // amountOut, reserveIn , reserveout
            transferWETHAmt = getAmountIn(getAmountCoinsNeededToBuy1WETHUnitAdjusted, reserve1, reserve0);
            WETH.transfer(address(pair), transferWETHAmt);
            // Get coin
            pair.swap(getAmountCoinsNeededToBuy1WETHUnitAdjusted, 0, address(this), "");
            IERC20(forToken).transfer(address(pair), getAmountCoinsNeededToBuy1WETHUnitAdjusted);
            pair.swap(0, 1 , msg.sender, "");
        }
        // console.log("Bought for ",transferWETHAmt);

        WETH.withdraw(msg.value.sub(transferWETHAmt));
        (bool success,) = msg.sender.call.value(address(this).balance)("");
    }



    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

  

}