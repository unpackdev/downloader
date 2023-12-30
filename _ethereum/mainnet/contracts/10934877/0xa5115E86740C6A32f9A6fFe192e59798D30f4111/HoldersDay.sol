pragma solidity 0.6.12;

//Note that assert() is now used because the try/catch mechanism in the Pamp.sol contract does not revert on failure with require();

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
        assert(c >= a/*, "SafeMath: addition overflow"*/);

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
        assert(b <= a/*, errorMessage*/);
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
        assert(c / a == b/*, "SafeMath: multiplication overflow"*/);

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
        assert(b > 0/*, errorMessage*/);
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
        assert(b != 0/*, errorMessage*/);
        return a % b;
    }
}

// Parent token contract, see Pamp.sol
abstract contract PampToken {
    function balanceOf(address account) public view virtual returns (uint256);
}

abstract contract StakingContract {
    function getStaker(address _staker) external virtual view returns (uint256, uint256, bool);
}

interface Minter {
    function liquidityRewards(address recipient, uint amount) external;
} 

contract HoldersDay {
    using SafeMath for uint256;
    
    PampToken token;
    address owner;
    Minter public minter;
    StakingContract public stakingContract;
    uint adjustmentFactor;
    
    uint32 public currentHoldersDayRewardedVersion;
    
    bool public enableHoldersDay;                     // once a month, holders receive a nice bump. This is true for 24 hours, once a month only.
    
    mapping (bytes32 => bool) public holdersDayRewarded; // Mapping to test whether an individual received his Holder's Day reward
    
    event HoldersDayEnabled();
    
    event HoldersDayRewarded(uint Amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        token = PampToken(0xF0FAC7104aAC544e4a7CE1A55ADF2B5a25c65bD1);
        stakingContract = StakingContract(0x738d3CEC4E685A2546Ab6C3B055fd6B8C1198093);
        minter = Minter(0x28e484dBD6BB501D37EFC8cD4b8dc33121cC78be);
        adjustmentFactor = 600;
    }
    
    // This function can be called once a month, when holder's day is enabled
    function claimHoldersDay() external {
        
        require(!getHoldersDayRewarded(msg.sender), "You've already claimed Holder's Day");
        require(enableHoldersDay, "Holder's Day is not enabled");

        (uint startTimestamp, uint lastTimestamp, bool hasMigrated) = stakingContract.getStaker(msg.sender);
        uint daysStaked = block.timestamp.sub(startTimestamp) / 86400;  // Calculate time staked in days
        require(daysStaked >= 30, "You must stake for 30 days to claim holder's day rewards");
        if (enableHoldersDay && daysStaked >= 30) {
            setHoldersDayRewarded(msg.sender);
            uint balance = token.balanceOf(msg.sender);
            uint numTokens = mulDiv(balance, daysStaked, adjustmentFactor);   // Once a month, holders get a nice bump
            uint tenPercent = mulDiv(balance, 1, 10);
        
            if (numTokens > tenPercent) {       // We don't allow a daily reward of greater than ten percent of a holder's balance.
                numTokens = tenPercent;
            }
            
            minter.liquidityRewards(msg.sender, numTokens);
            emit HoldersDayRewarded(numTokens);
        }
        
    }

    function getHoldersDayRewarded(address holder) internal view returns(bool) {
        bytes32 key = keccak256(abi.encodePacked(currentHoldersDayRewardedVersion, holder));
        return holdersDayRewarded[key];
    }

    function setHoldersDayRewarded(address holder) internal {
        bytes32 key = keccak256(abi.encodePacked(currentHoldersDayRewardedVersion, holder));
        holdersDayRewarded[key] = true;
    }

    function deleteHoldersDayRewarded() internal {
        currentHoldersDayRewardedVersion++;
    }
        
    function updateHoldersDay(bool _enableHoldersDay) external onlyOwner {
        enableHoldersDay = _enableHoldersDay;
        if(enableHoldersDay) {
            deleteHoldersDayRewarded();
            emit HoldersDayEnabled();
        }
    }
    
    function updateAdjustmentFactor(uint _adjustmentFactor) external onlyOwner {
        adjustmentFactor = _adjustmentFactor;
    }
    
    function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }
    
    function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }
}