/**
   ______                      __  ____        __                      __  ____  _ __    
  / ____/___ _______________  / /_/ __ )____ _/ /___ _____  ________  / / / / /_(_) /____
 / /   / __ `/ ___/ ___/ __ \/ __/ __  / __ `/ / __ `/ __ \/ ___/ _ \/ / / / __/ / / ___/
/ /___/ /_/ / /  / /  / /_/ / /_/ /_/ / /_/ / / /_/ / / / / /__/  __/ /_/ / /_/ / (__  ) 
\____/\__,_/_/  /_/   \____/\__/_____/\__,_/_/\__,_/_/ /_/\___/\___/\____/\__/_/_/____/
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/CarrotBalanceUtils.sol

pragma solidity ^0.5.17;

/* this contract is a read only utility to calculate Carrot balances faster on the website */

contract CarrotBalanceUtils {
    using SafeMath for uint256;

    ITokenUtils public Carrot = ITokenUtils(0xa08dE8f020644DCcd0071b3469b45B08De41C38b); // Carrot Token address
    ITokenUtils public uniswapPair = ITokenUtils(Carrot.uniswapV2Pair());

    function CarrotBalance(address _user) public view returns (uint256) {
        return Carrot.balanceOf(_user);
    }

    function CarrotBalanceInUniswap(address _user) public view returns (uint256) {
        uint256 uniswapPairCarrotBalance = Carrot.balanceOf(address(uniswapPair));
        if (uniswapPairCarrotBalance == 0) {
            return 0;
        }
        uint256 userLpBalance = uniswapPair.balanceOf(_user);
        if (userLpBalance == 0) {
            return 0;
        }
        uint256 userPercentOfLpOwned = userLpBalance.mul(1e12).div(uniswapPair.totalSupply());
        return uniswapPairCarrotBalance.mul(userPercentOfLpOwned).div(1e12);
    }

    function CarrotBalanceAll(address _user) public view returns (uint256) {
        return CarrotBalance(_user).add(CarrotBalanceInUniswap(_user));
    }

    function balanceOf(address _user) external view returns (uint256) {
        return CarrotBalanceAll(_user);
    }

    function circulatingSupply() public view returns (uint256) {
        uint256 lockedSupply = Carrot.lockedSupply();
        return Carrot.totalSupply().sub(lockedSupply);
    }

    function totalSupply() external view returns (uint256) {
        return circulatingSupply();
    }
}

interface ITokenUtils {
    function lockedSupply() external view returns (uint);
    function uniswapV2Pair() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
}