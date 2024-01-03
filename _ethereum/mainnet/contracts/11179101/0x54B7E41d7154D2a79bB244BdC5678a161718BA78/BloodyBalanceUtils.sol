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
     *
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
     *
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
     *
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

/* this contract is a read only utility to calculate bloody balances faster on the website */

contract BloodyBalanceUtils {
    using SafeMath for uint256;

    IERC20 public bloody;
    IChef public zombieChef;
    IChef public policeChief;

    constructor(IERC20 _bloody, IChef _zombieChef, IChef _policeChief) public {
        bloody = _bloody;
        zombieChef = _zombieChef;
        policeChief = _policeChief;
    }

    function bloodyBalance(address _user) external view returns (uint256) {
        return bloody.balanceOf(_user);
    }

    function bloodyBalanceStakedInRot(address _user) public view returns (uint256) {
        uint256 totalRotStaked = 0;
        uint256 poolCount = zombieChef.poolLength();
        for (uint256 pid = 0; pid < poolCount; ++pid) {
            (uint256 amount, uint256 rewardDebt) = zombieChef.userInfo(pid, _user);
            if (amount == 0) {
                continue;
            }
            (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = zombieChef.poolInfo(pid);
            uint256 uniswapPairRotBalance = bloody.balanceOf(address(lpToken));
            if (uniswapPairRotBalance == 0) {
                continue;
            }
            uint256 userPercentOfLpOwned = amount.mul(1e12).div(lpToken.totalSupply());
            totalRotStaked = totalRotStaked.add(uniswapPairRotBalance.mul(userPercentOfLpOwned).div(1e12));
        }
        return totalRotStaked;
    }

    function bloodyBalanceStakedInNice(address _user) public view returns (uint256) {
        uint256 totalRotStaked = 0;
        uint256 poolCount = policeChief.poolLength();
        for (uint256 pid = 0; pid < poolCount; ++pid) {
            (uint256 amount, uint256 rewardDebt) = policeChief.userInfo(pid, _user);
            if (amount == 0) {
                continue;
            }
            (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = policeChief.poolInfo(pid);
            uint256 uniswapPairRotBalance = bloody.balanceOf(address(lpToken));
            if (uniswapPairRotBalance == 0) {
                continue;
            }
            uint256 userPercentOfLpOwned = amount.mul(1e12).div(lpToken.totalSupply());
            totalRotStaked = totalRotStaked.add(uniswapPairRotBalance.mul(userPercentOfLpOwned).div(1e12));
        }
        return totalRotStaked;
    }

    function bloodyBalanceAll(address _user) public view returns (uint256) {
        return bloody.balanceIncludingUniswapPairs(_user).add(bloodyBalanceStakedInRot(_user)).add(bloodyBalanceStakedInNice(_user));
    }

    function totalSupply() public view returns (uint256) {
        uint256 elasticModifier = uint256(1000).div(bloody.minBurnDivisor()).sub(uint256(1000).div(bloody.maxBurnDivisor())).div(2);
        return bloody.totalSupply().mul(elasticModifier);
    }

    function totalSupplyBurned() public view returns (uint256) {
        uint256 elasticModifier = uint256(1000).div(bloody.minBurnDivisor()).sub(uint256(1000).div(bloody.maxBurnDivisor())).div(2);
        return bloody.totalSupplyBurned().mul(elasticModifier);
    }

    function balanceOf(address _user) public view returns (uint256) {
        return bloodyBalanceAll(_user);
    }
}

interface IChef {
    function poolInfo(uint256 pid) external view returns (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShar);
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
    function sushiPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function balanceIncludingUniswapPairs(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
    function totalSupplyBurned() external view returns (uint256);
    function minBurnDivisor() external view returns (uint256);
    function maxBurnDivisor() external view returns (uint256);
}