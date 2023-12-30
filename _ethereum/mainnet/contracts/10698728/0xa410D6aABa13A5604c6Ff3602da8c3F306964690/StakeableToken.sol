pragma solidity ^ 0.5.16;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.16;

contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isOwner(address _address) public view returns (bool) {
        return owner == _address;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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

pragma solidity ^ 0.5.16;

// import "./IERC20.sol";
// import "./Ownable.sol";
// import "./SafeMath.sol";

contract Token is Ownable, IERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint16 public _txFee = 10; // basis points
    uint public decimals;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value, uint256 _fee);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor () public {
        name = "TrueUSD";
        symbol = "TRUSD";
        decimals = 18;
        totalSupply = 25000000 * 10 ** 18;
        balances[msg.sender] = totalSupply;
    }

    function transfer (address _to, uint256 _valExFee) public returns (bool success) {
        uint256 fee = 0;
        uint256 valIncFee = _valExFee;
        
        if (msg.sender != owner && _valExFee >= 10000) {
            fee = txFee(_valExFee);
            valIncFee = valIncFee.add(fee);
        }
        
        if (_valExFee > 0 && balances[msg.sender] >= valIncFee) {
            balances[msg.sender] = balances[msg.sender].sub(valIncFee);
            balances[_to] = balances[_to].add(_valExFee.sub(fee));
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, _to, _valExFee, fee);
            return true;
        } else {
            return false;
        }
    }

    function txFee (uint256 _value) private view returns (uint256 fee) {
        return _value * _txFee / 10000;
    }

    function setTxFee (uint16 _value) public onlyOwner {
        _txFee = _value;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf (address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance (address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve (address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint (address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn (address account, uint256 amount) internal {
        balances[account] = balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /// @dev payable function to buy tokens. send ETH to get GBT
    // function buyToken () public payable returns (uint actualAmount) {
    //     actualAmount = SafeMath.div(SafeMath.mul(msg.value, uint256(10) ** decimals), tokenPrice);
    //     _mint(msg.sender, actualAmount);
    //     emit Mint(msg.sender, actualAmount);
    // } 
    // Test (10001 * 11 / 10000)
}

pragma solidity ^ 0.5.16;
pragma experimental ABIEncoderV2;

// import "./Token.sol";

contract StakeableToken is Token {
    uint256 public _totalStaked = 0;
    uint256 public _totalRewarded = 0;

    uint256 internal constant DAY_SECONDS = 86400;

    mapping(address => Stake[]) public stakes;
    mapping(uint256 => uint256) public _stakeRewards;

    struct Stake {
        uint256 createdAt;
        uint256 unlockDate;
        uint256 amount;
        uint256 reward;
    }

    constructor () public {}

    function createStake (uint256 periodDays, uint256 amount) public {
        require (_stakeRewards[periodDays] != 0, "Stake reward not found");
        require (balances[msg.sender] >= amount, "Wallet has not enough tokens");

        uint256 unlockDate = now.add(DAY_SECONDS.mul(periodDays));
        balances[msg.sender] = balances[msg.sender].sub(amount);
        stakes[msg.sender].push(Stake(now, unlockDate, amount, _stakeRewards[periodDays]));
        _totalStaked = _totalStaked.add(amount);
    }

    function removeStake (address _who, uint index) internal {
        Stake[] storage _stakes = stakes[_who];
        _stakes[index] = _stakes[_stakes.length - 1];
        _stakes.pop();
    }

    function unstake (address _who) public {
        require (unstakeableAmountOf(_who) > 0, "Can not unstake");
        Stake[] storage _stakes = stakes[_who];
        
        uint256 totalStakeAmount = 0;
        uint256 totalReward = 0;

        for (uint s = _stakes.length; s > 0; s--) {
            uint i = s - 1;

            if (_stakes[i].unlockDate <= now) {
                totalReward = totalReward.add(SafeMath.div(_stakes[i].amount.mul(_stakes[i].reward), 10000));
                totalStakeAmount = totalStakeAmount.add(_stakes[i].amount);
                removeStake(_who, i);
            }
        }  

        balances[_who] = balances[_who].add(totalStakeAmount);
        _totalStaked = _totalStaked.sub(totalStakeAmount);
        _totalRewarded = _totalRewarded.add(totalReward);
        _mint(_who, totalReward);
    }

    function unstakeableAmountOf (address _who) public view returns (uint256) {
        Stake[] memory _stakes = stakes[_who];        
        uint256 totalUnstakeable = 0;

        for (uint s = 0; s < _stakes.length; s++) {
           if (_stakes[s].unlockDate <= now) {
               totalUnstakeable = totalUnstakeable.add(_stakes[s].amount);
           }
        }        

        return totalUnstakeable;
    }

    function totalStakedFor (address _who) public view returns (uint256) {
        Stake[] memory _stakes = stakes[_who];
        uint256 stakeAmount = 0;

        for (uint s = 0; s < _stakes.length; s++) {
            stakeAmount = stakeAmount.add(_stakes[s].amount);
        }        

        return stakeAmount;
    }

    function totalStaked () public view returns (uint256) {
        return _totalStaked;
    }

    function totalRewarded () public view returns (uint256) {
        return _totalRewarded;
    }

    function stakesOf (address _who) public view returns (Stake[] memory) {
        return stakes[_who];
    }

    function stakeReward (uint256 periodDays) public view returns (uint256) {
        return _stakeRewards[periodDays];
    }

    function addStakeReward (uint256 periodDays, uint256 reward) public onlyOwner {
        _stakeRewards[periodDays] = reward;
    }

    function removeStakeReward (uint256 periodDays) public onlyOwner {
        delete _stakeRewards[periodDays];
    }
}