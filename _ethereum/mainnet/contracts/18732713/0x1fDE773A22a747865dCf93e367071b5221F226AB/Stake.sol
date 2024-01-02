// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface ISlopyToken {
    function balanceOf(address account) external view returns (uint256);

    function isWhiteList(address account) external view returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract Stake is Ownable {
    using SafeMath for uint256;
    ISlopyToken public token;
    uint256 public rewardRate3;
    uint256 public rewardRate6;
    uint256 public rewardRate12;
    uint256 public divisorRate;

    struct StakerData {
        uint256 endStaking;
        uint256 totalStaked;
        uint256 reward;
    }

    mapping(address => StakerData[]) private stakers;

    uint256 private totalReward;

    event TokensStaked(address indexed user, uint256 amount, uint256 duration);
    event TokensUnstaked(address indexed user, uint256 amount);

    constructor(ISlopyToken _token, uint256 _rewardRate3, uint256 _rewardRate6, uint256 _rewardRate12, uint256 _divisorRate) {
        token = _token;
        rewardRate3 = _rewardRate3;
        rewardRate6 = _rewardRate6;
        rewardRate12 = _rewardRate12;
        divisorRate = _divisorRate;
    }

    function getStakerData() public view returns(StakerData[] memory) {
        return stakers[msg.sender];
    }

    function getMaxAvail(uint256 _duration) public view returns(uint256) {
        if (_duration < 3 || token.balanceOf(address(this)) <= (totalReward)) {
            return 0;
        } else if (_duration < 6) {
            if (!token.isWhiteList(msg.sender)) {
                return token.balanceOf(address(this)).sub(totalReward).mul(divisorRate).div(rewardRate3.div(4)).mul(100000).div(99912);
            } else {
                return token.balanceOf(address(this)).sub(totalReward).mul(divisorRate).div(rewardRate3.div(4));
            }
        } else if (_duration < 12) {
            if (!token.isWhiteList(msg.sender)) {
                return token.balanceOf(address(this)).sub(totalReward).mul(divisorRate).div(rewardRate6.div(2)).mul(100000).div(99912);
            } else {
                return token.balanceOf(address(this)).sub(totalReward).mul(divisorRate).div(rewardRate6.div(2));
            }
        } else {
            if (!token.isWhiteList(msg.sender)) {
                return token.balanceOf(address(this)).sub(totalReward).mul(divisorRate).div(rewardRate12).mul(100000).div(99912);
            } else {
                return token.balanceOf(address(this)).sub(totalReward).mul(divisorRate).div(rewardRate12);
            }
        }
    }

    function stake(uint256 _amount, uint256 _duration) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(_duration >= 3, "Duration must be greater than or equal 3 month");

        if (_duration < 6) {
            require(getMaxAvail(3) >= _amount, "Amount is more than available");

            if (!token.isWhiteList(msg.sender)) {
                uint256 amount = _amount.sub(_amount.mul(88).div(100000));
                stakers[msg.sender].push(StakerData(
                    block.timestamp.add(7776000), 
                    amount, 
                    amount.mul(rewardRate3).div(divisorRate).div(4)
                ));
            } else {
                stakers[msg.sender].push(StakerData(
                    block.timestamp.add(7776000), 
                    _amount, 
                    _amount.mul(rewardRate3).div(divisorRate).div(4)
                ));
            }

        } else if (_duration < 12) {
            require(getMaxAvail(6) >= _amount, "Amount is more than available");

            if (!token.isWhiteList(msg.sender)) {
                uint256 amount = _amount.sub(_amount.mul(88).div(100000));
                stakers[msg.sender].push(StakerData(
                    block.timestamp.add(15552000), 
                    amount, 
                    amount.mul(rewardRate6).div(divisorRate).div(2)
                ));
            } else {
                stakers[msg.sender].push(StakerData(
                    block.timestamp.add(15552000), 
                    _amount, 
                    _amount.mul(rewardRate6).div(divisorRate).div(2)
                ));
            }
        } else {
            require(getMaxAvail(12) >= _amount, "Amount is more than available");

            if (!token.isWhiteList(msg.sender)) {
                uint256 amount = _amount.sub(_amount.mul(88).div(100000));
                stakers[msg.sender].push(StakerData(
                    block.timestamp.add(31104000), 
                    amount, 
                    amount.mul(rewardRate12).div(divisorRate)
                ));
            } else {
                stakers[msg.sender].push(StakerData(
                    block.timestamp.add(31104000), 
                    _amount, 
                    _amount.mul(rewardRate12).div(divisorRate)
                ));
            }
        }

        totalReward = totalReward.add(stakers[msg.sender][stakers[msg.sender].length.sub(1)].totalStaked).add(stakers[msg.sender][stakers[msg.sender].length.sub(1)].reward);
        token.transferFrom(msg.sender, address(this), _amount);
        emit TokensStaked(msg.sender, _amount, _duration);
    }

    function claim() public {
        require(stakers[msg.sender].length > 0, "Stake already withdraw");

        uint256 _claimAmount = 0;
        uint256 _index = 0;

        for (uint256 i = 0; i < stakers[msg.sender].length; i++) {
            if (stakers[msg.sender][i].endStaking < block.timestamp) {
                _claimAmount = _claimAmount.add(stakers[msg.sender][i].totalStaked).add(stakers[msg.sender][i].reward);
                totalReward = totalReward.sub(stakers[msg.sender][i].totalStaked.add(stakers[msg.sender][i].reward));
                emit TokensUnstaked(msg.sender, stakers[msg.sender][i].totalStaked.add(stakers[msg.sender][i].reward));
            } else {
                stakers[msg.sender][_index] = (stakers[msg.sender][i]);
                _index++;
            }
        }

        require(_claimAmount > 0, "Available for claim 0");

        while (stakers[msg.sender].length > _index) {
            stakers[msg.sender].pop();
        }

        token.transfer(msg.sender, _claimAmount);
    }

    // only owner function

    function getStakersData(address _address) public onlyOwner view returns(StakerData[] memory) {
        return stakers[_address];
    }

    function withdraw(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    function getTotalReward() public onlyOwner view returns(uint256) {
        return totalReward;
    }

    function setRewardRate(uint256 _rewardRate3, uint256 _rewardRate6, uint256 _rewardRate12) public onlyOwner {
        rewardRate3 = _rewardRate3;
        rewardRate6 = _rewardRate6;
        rewardRate12 = _rewardRate12;
    }

    function setRewardRate(uint256 _divisorRate) public onlyOwner {
        divisorRate = _divisorRate;
    }
}