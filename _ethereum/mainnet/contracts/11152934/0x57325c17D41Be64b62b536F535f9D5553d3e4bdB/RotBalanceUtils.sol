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

// File: contracts/RotBalanceUtils.sol

pragma solidity ^0.6.2;


// this contract is a read only utility to calculate rot balances faster on the website

contract RotBalanceUtils {
    using SafeMath for uint256;

    IERC20 public rotten;
    IZombieChef public zombieChef;

    constructor(IERC20 _rotten, IZombieChef _zombieChef) public {
        rotten = _rotten;
        zombieChef = _zombieChef;
    }

    function rotBalance(address _user) external view returns (uint256) {
        return rotten.balanceOf(_user);
    }

    function rotBalancePendingHarvest(address _user) public view returns (uint256) {
        uint256 totalPendingRot = 0;
        uint256 poolCount = zombieChef.poolLength();
        for (uint256 pid = 0; pid < poolCount; ++pid) {
            (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = zombieChef.poolInfo(pid);
            (uint256 amount, uint256 rewardDebt) = zombieChef.userInfo(pid, _user);
            uint256 lpSupply = lpToken.balanceOf(address(zombieChef));
            if (block.number > lastRewardBlock && lpSupply != 0) {
                uint256 multiplier = zombieChef.getMultiplier(lastRewardBlock, block.number);
                uint256 rottenReward = multiplier.mul(zombieChef.sushiPerBlock()).mul(allocPoint).div(zombieChef.totalAllocPoint());
                accSushiPerShare = accSushiPerShare.add(rottenReward.mul(1e12).div(lpSupply));
            }
            totalPendingRot = totalPendingRot.add(amount.mul(accSushiPerShare).div(1e12).sub(rewardDebt));
        }
        return totalPendingRot;
    }

    function rotBalanceStaked(address _user) public view returns (uint256) {
        uint256 totalRotStaked = 0;
        uint256 poolCount = zombieChef.poolLength();
        for (uint256 pid = 0; pid < poolCount; ++pid) {
            (uint256 amount, uint256 rewardDebt) = zombieChef.userInfo(pid, _user);
            if (amount == 0) {
                continue;
            }
            (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) = zombieChef.poolInfo(pid);
            uint256 uniswapPairRotBalance = rotten.balanceOf(address(lpToken));
            if (uniswapPairRotBalance == 0) {
                continue;
            }
            uint256 userPercentOfLpOwned = amount.mul(1e12).div(lpToken.totalSupply());
            totalRotStaked = totalRotStaked.add(uniswapPairRotBalance.mul(userPercentOfLpOwned).div(1e12));
        }
        return totalRotStaked;
    }

    function rotBalanceAll(address _user) external view returns (uint256) {
        return rotten.balanceOf(_user).add(rotBalanceStaked(_user)).add(rotBalancePendingHarvest(_user));
    }
}

interface IZombieChef {
    function poolInfo(uint256 pid) external view returns (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShar);
    function userInfo(uint256 pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
    function sushiPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
}