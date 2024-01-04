// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}
contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract STAKE_B2U is Ownable {
    using SafeMath for uint256;

    struct StakingInfo {
        uint256 amount;
        uint256 depositDate;
        uint256 rewardPercent;
    }

    uint256 minStakeAmount = 10 * 10**18; 
    uint256 REWARD_DIVIDER = 10**8;
    uint256 UNSTAKE_FEE = 2 * 10**18; 
    uint256 CHANGE_REWARD = 1500000 * 10**18;

    IERC20 stakingToken;
    uint256 rewardPercent; 
    string name = "Staking B2U";

    uint256 ownerTokensAmount;
    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;

    //  percent value for per second
    //  set 192 if you want 2% per month reward (because it will be divided by 10^8 for getting the small float number)
    //  2% per month = 2 / (30 * 24 * 60 * 60) ~ 0.00000077 (77 / 10^8)
    constructor(IERC20 _stakingToken, uint256 _rewardPercent) {
        stakingToken = _stakingToken;
        rewardPercent = _rewardPercent;
    }

    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);

    function changeRewardPercent(uint256 _rewardPercent) public onlyOwner {
        rewardPercent = _rewardPercent;
    }

    function changeMinStakeAmount(uint256 _minStakeAmount) public onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            for (uint256 j = 0; j < stakes[stakeholders[i]].length; j += 1)
                _totalStakes = _totalStakes.add(
                    stakes[stakeholders[i]][j].amount
                );
        }
        return _totalStakes;
    }

    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    function stake(uint256 _amount) public {
        require(_amount >= minStakeAmount);
        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "Stake required!"
        );
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        
        uint256 tvl = totalStakes();
        if(tvl < CHANGE_REWARD) {
            stakes[msg.sender].push(StakingInfo(_amount, block.timestamp, rewardPercent));
            emit Staked(msg.sender, _amount);
        } else {
            stakes[msg.sender].push(StakingInfo(_amount, block.timestamp, 38));
            emit Staked(msg.sender, _amount);
        }
    }

    function unstake() public {
        uint256 withdrawAmount = 0;
        for (uint256 j = 0; j < stakes[msg.sender].length; j += 1) {
            uint256 amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);

            uint256 rewardAmount = amount.mul(
                (block.timestamp - stakes[msg.sender][j].depositDate).mul(
                    stakes[msg.sender][j].rewardPercent
                )
            );
            rewardAmount = rewardAmount.div(REWARD_DIVIDER);
            withdrawAmount = withdrawAmount.add(rewardAmount.div(100));
        }
        
        uint256 withAmount = withdrawAmount.sub(UNSTAKE_FEE);
        
        require(stakingToken.transfer(owner, UNSTAKE_FEE),  "Not enough tokens in contract!");
        
        require(
            stakingToken.transfer(msg.sender, withAmount),
            "Not enough tokens in contract!"
        );
        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }

    function sendTokens(uint256 _amount) public onlyOwner {
        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "Transfering not approved!"
        );
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }

    function withdrawTokens(address receiver, uint256 _amount)
        public
        onlyOwner
    {
        ownerTokensAmount = ownerTokensAmount.sub(_amount);
        require(
            stakingToken.transfer(receiver, _amount),
            "Not enough tokens on contract!"
        );
    }
   
       
        function dailyStakeRewards(address _user) public view returns (uint256) {
        address user = _user;
        uint256 _amount = 0;
        uint256 _rewardPercent = 0;
        uint256 _depositeDate = 0 ;
        uint256 _rewardAmount = 0;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
                
            for (uint256 j = 0; j < stakes[user].length; j += 1)
                _amount = _amount.add(
                   
                    stakes[user][j].amount
                );
            for (uint256 j = 0; j < stakes[user].length; j += 1)
                _rewardPercent = _rewardPercent.add(
                    stakes[user][j].rewardPercent
                );
            for (uint256 j = 0; j < stakes[user].length; j += 1)
                _depositeDate = _depositeDate.add(
                    stakes[user][j].depositDate
                );   
            uint256 _rewardcalculation = _amount.mul((block.timestamp - _depositeDate).mul(
                _rewardPercent));
                _rewardAmount =_rewardcalculation.div(REWARD_DIVIDER); 
                 
        }   
    
        return _rewardAmount;
    }
}