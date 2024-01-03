// File: contracts/SafeMath.sol

pragma solidity ^0.6.0;

contract SafeMath {

 
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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeSub(a, b, "SafeMath: subtraction overflow");
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
    function safeSub(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b <= a, error);
        uint256 c = a - b;
        return c;
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
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeDiv(a, b, "SafeMath: division by zero");
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
    function safeDiv(uint256 a, uint256 b, string memory error) internal pure returns (uint256) {
        require(b > 0, error);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function safeExponent(uint256 a,uint256 b) internal pure returns (uint256) {
      uint256 result;
      assembly {
          result:=exp(a, b)	
      }
      return result;
  }
    
    
}

// File: contracts/IERC20.sol
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

// File: contracts/Ownable.sol

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
contract Ownable {
    
    address payable public owner;
    
    address payable public newOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _trasnferOwnership(msg.sender);
    }
    
    function _trasnferOwnership(address payable _whom) internal {
        emit OwnershipTransferred(owner,_whom);
        owner = _whom;
    }
    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "ERR_AUTHORIZED_ADDRESS_ONLY");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable _newOwner)
        external
        virtual
        onlyOwner
    {
        require(_newOwner != address(0),"ERR_ZERO_ADDRESS");
        newOwner = _newOwner;
    }
    
    function acceptOwnership() external
        virtual
        returns (bool){
            require(msg.sender == newOwner,"ERR_ONLY_NEW_OWNER");
            owner = newOwner;
            emit OwnershipTransferred(owner, newOwner);
            newOwner = address(0);
            return true;
        }
    
    
}

// File: contracts/YgfStake.sol

pragma solidity ^0.6.0;




contract YgfStaking is SafeMath, Ownable {
    uint256 public constant DECIMAL_NOMINATOR = 10**18;

    uint256 public totalStackAmount = 0;
    uint256 public constant rewardBreakingPoint = 28;

    // used in 100 mulitipliction
    uint256 public constant beforeBreakPoint = 50;
    // used in 100 mulitipliction
    uint256 public constant aterBreakPoint = 100;
    // used in 100 mulitipliction
    uint256 public constant stakeFee = 1000;

    uint256 public constant MIN_AMOUNT = 1 * DECIMAL_NOMINATOR;
    uint256 public constant MAX_AMOUNT = 500 * DECIMAL_NOMINATOR;

    address public token;

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastStack;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address _token) public {
        token = _token;
    }

    // To stake token user will call this method
    // user can stake only once while
    // 10% fee on stake is distrubuted among other staker
    // store totalStackAmount based on calulation so we keep track record for number of staked token
    function stake(uint256 amount) external returns (bool) {
        require(
            amount >= MIN_AMOUNT && amount <= MAX_AMOUNT,
            "ERR_MIN_MAX_CONDITION_NOT_FULLFILLED"
        );
        require(stakedAmount[msg.sender] == 0, "ERR_ALREADY_STACKED");
        bool isOk = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(isOk, "ERR_TOKEN_TRANSFER_FAIL");
        emit Staked(msg.sender, amount);
        uint256 _fee = safeDiv(safeMul(amount, stakeFee), 10000);
        stakedAmount[msg.sender] = safeSub(amount, _fee);
        lastStack[msg.sender] = now;
        totalStackAmount = safeAdd(totalStackAmount, safeSub(amount, _fee));
        return true;
    }

    // all penalty is in 100 mulitipliction
    function penalityChecker(uint256 _days) internal pure returns (uint256) {
        if (_days > 84) {
            return 0;
        } else if (_days > 56) {
            return 500;
        } else if (_days > 28) {
            return 1000;
        } else {
            return 2000;
        }
    }

    // To unstake token user will call this method
    // user will get penalty if they unstack before 84 days
    // user get daily rewards according to calulation
    // sub from totalStackAmount what user stacke erlier so if there is no stacke it wil become zero
    //  for first 28 days we give 0.5 rewards per day
    //  after 29 day reward is 1% per day
    function unStake() external returns (bool) {
        require(stakedAmount[msg.sender] != 0, "ERR_NOT_STACKED");
        uint256 lastStackTime = lastStack[msg.sender];
        uint256 amount = stakedAmount[msg.sender];
        uint256 _days = safeDiv(safeSub(now, lastStackTime), 86400);

        uint256 totalReward = 0;

        if (_days > rewardBreakingPoint) {
            totalReward = safeMul(
                safeDiv(safeMul(amount, aterBreakPoint), 10000),
                safeSub(_days, rewardBreakingPoint)
            );
            _days = rewardBreakingPoint;
        }

        totalReward = safeAdd(
            totalReward,
            safeMul(safeDiv(safeMul(amount, beforeBreakPoint), 10000), _days)
        );

        uint256 totalAmount = safeAdd(amount, totalReward);
        uint256 penalty = penalityChecker(_days);

        uint256 penaltyAmount = safeDiv(safeMul(totalAmount, penalty), 10000);
        uint256 recivedAmount = safeSub(totalAmount, penaltyAmount);

        emit Unstaked(msg.sender, recivedAmount);
        IERC20(token).transfer(msg.sender, recivedAmount);

        totalStackAmount = safeSub(totalStackAmount, amount);
        stakedAmount[msg.sender] = 0;
        lastStack[msg.sender] = 0;

        return true;
    }

    // owner can take out token from stack if totalStackAmount amount is less then  DECIMAL_NOMINATOR
    // we check decimal nominator if there is any
    function transferToken(uint256 amount) external onlyOwner() returns (bool) {
        require(totalStackAmount < DECIMAL_NOMINATOR, "ERR_THERE_IS_STACKING");
        return IERC20(token).transfer(msg.sender, amount);
    }

    // user can check how many day passed untill they stake
    function checkDays(address _whom) external view returns (uint256) {
        uint256 lastStackTime = lastStack[_whom];
        uint256 _days = safeDiv(safeSub(now, lastStackTime), 86400);
        return _days;
    }

    // user can check how much penalty is there if they unstake now
    function checkPenality(address _whom) external view returns (uint256) {
        uint256 lastStackTime = lastStack[_whom];
        uint256 _days = safeDiv(safeSub(now, lastStackTime), 86400);
        uint256 penalty = penalityChecker(_days);
        return penalty;
    }

    // user can check balance if they unstake now
    function balanceOf(address _whom) external view returns (uint256) {
        uint256 lastStackTime = lastStack[_whom];
        uint256 amount = stakedAmount[_whom];
        uint256 _days = safeDiv(safeSub(now, lastStackTime), 86400);
        
        uint256 totalReward = 0;
        
        if (_days > rewardBreakingPoint) {
            totalReward = safeMul(
                safeDiv(safeMul(amount, aterBreakPoint), 10000),
                safeSub(_days, rewardBreakingPoint)
            );
            _days = rewardBreakingPoint;
        }

        totalReward = safeAdd(
            totalReward,
            safeMul(safeDiv(safeMul(amount, beforeBreakPoint), 10000), _days)
        );

        uint256 totalAmount = safeAdd(amount, totalReward);
        uint256 penalty = penalityChecker(_days);
        uint256 penaltyAmount = safeDiv(safeMul(totalAmount, penalty), 10000);
        uint256 recivedAmount = safeSub(totalAmount, penaltyAmount);
        return recivedAmount;
    }
}