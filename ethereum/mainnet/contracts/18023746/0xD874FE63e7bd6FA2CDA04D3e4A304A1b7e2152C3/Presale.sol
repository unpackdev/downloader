// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
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
        require(c >= a, 'SafeMath: addition overflow');
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
        require(b <= a, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');
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
        require(b > 0, 'SafeMath: division by zero');
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
        require(b > 0, 'SafeMath: modulo by zero');
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract Presale is Ownable {
    using SafeMath for uint;

    struct UserInfo {
        uint fcBought;
        uint fcClaimed;
        bool isBuyer;
        uint usdt;
        uint eth;
        bool isRefundable;
    }

    mapping(address => UserInfo) public userInfo;

    // Fri Sep 01 2023 00:00:00 GMT+0000
    uint public startTime = 1693526400;

    struct PresaleStage {
        uint period;
        uint rateUsdt;
    }

    PresaleStage[] public presaleStage;

    bool public isClaimable;

    // total FC sold
    uint public totalFcSold;
    // 50000 usdt
    uint public maxBuyUsdtAmount = 50000 * 1e6;
    // 30 eth
    uint public maxBuyEthAmount = 30 * 1e18;
    // 2.5 millions usdt
    uint public softCap = 2500000 * 1e6;
    // 20 millions usdt
    uint public hardCap = 20000000 * 1e6;
    // total investors
    uint public totalContributors;

    uint public totalEth;
    uint public totalUsdt;

    // Furr coin token
    IERC20 public token;
    IERC20 public Usdt;

    AggregatorV3Interface ethUsdtFeed;

    constructor(address _token, address _usdt, address _feed) public {
        require(_token != address(0), 'Invalid token address');
        token = IERC20(_token);
        Usdt = IERC20(_usdt);
        ethUsdtFeed = AggregatorV3Interface(_feed);
        addStage(2 weeks, 0.00001 * 1e6);
        addStage(2 weeks, 0.0001 * 1e6);
        addStage(4 weeks, 0.001 * 1e6);
        addStage(4 weeks, 0.01 * 1e6);
    }

    function addStage(uint _period, uint _rateUsdt) public onlyOwner {
        presaleStage.push(PresaleStage({period: _period, rateUsdt: _rateUsdt}));
    }

    function updateStage(uint _stage, uint _period, uint _rateUsdt) public onlyOwner {
        (uint _currentStage, , , ) = currentPresaleState();
        require(_stage > _currentStage || block.timestamp < startTime, 'The stage was already started');
        presaleStage[_stage].period = _period;
        presaleStage[_stage].rateUsdt = _rateUsdt;
    }

    function stageLength() public view returns (uint) {
        return presaleStage.length;
    }

    function currentPresaleState() public view returns (uint, uint, uint, uint) {
        uint currentTime = block.timestamp;
        if (currentTime < startTime) {
            return (0, 0, startTime, presaleStage[0].rateUsdt);
        }
        uint length = stageLength();
        uint stageStartTime = startTime;
        uint stageEndTime;
        for (uint i = 0; i < length; i++) {
            stageEndTime = stageStartTime.add(presaleStage[i].period);
            if (stageStartTime <= currentTime && currentTime <= stageEndTime) {
                return (i, stageStartTime, stageEndTime, presaleStage[i].rateUsdt);
            }
            stageStartTime = stageEndTime;
        }
        return (length, 0, block.timestamp, 0);
    }

    function getEthUsdtPrice() public view returns (int) {
        (, int price, , , ) = ethUsdtFeed.latestRoundData();
        return price;
    }

    function buy(uint _usdtAmount) public payable {
        require(block.timestamp > startTime, 'Presale is not started');
        address _user = msg.sender;
        UserInfo storage user = userInfo[_user];
        require(user.eth + msg.value <= maxBuyEthAmount, 'Max buy eth!');
        require(user.usdt + _usdtAmount <= maxBuyUsdtAmount, 'Max buy Usdt!');
        (, , , uint _rateUsdt) = currentPresaleState();
        if (_usdtAmount > 0) {
            Usdt.transferFrom(_user, address(this), _usdtAmount);
        }
        uint _fcBoughtUsdt = _usdtAmount.mul(1e18).div(_rateUsdt);
        int ethPrice = getEthUsdtPrice();
        uint _fcBoughtEth = msg.value.mul(1e6).div(_rateUsdt).mul(uint(ethPrice)).div(1e8);
        uint _fcBought = _fcBoughtUsdt + _fcBoughtEth;
        totalFcSold = totalFcSold.add(_fcBought);
        user.fcBought += _fcBought;
        if (user.isBuyer == false) {
            user.isBuyer = true;
            totalContributors += 1;
        }
        totalUsdt += _usdtAmount;
        totalEth += msg.value;
        user.usdt += _usdtAmount;
        user.eth += msg.value;
    }

    function toogleClaim() public onlyOwner {
        isClaimable = !isClaimable;
    }

    function claim() public {
        require(isClaimable, 'Not claimable');
        UserInfo storage user = userInfo[msg.sender];
        uint unclaimed = user.fcBought.sub(user.fcClaimed);
        require(unclaimed > 0, 'No amount to claim');
        require(unclaimed < token.balanceOf(address(this)), 'Insufficient token balance');
        token.transfer(msg.sender, unclaimed);
        user.fcClaimed += unclaimed;
        totalFcSold += unclaimed;
    }

    function setStartTime(uint _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setMaxBuyAmount(uint _maxBuyUsdtAmount, uint _maxBuyEthAmount) public onlyOwner {
        maxBuyUsdtAmount = _maxBuyUsdtAmount;
        maxBuyEthAmount = _maxBuyEthAmount;
    }

    function setCap(uint _softCap, uint _hardCap) public onlyOwner {
        softCap = _softCap;
        hardCap = _hardCap;
    }

    // withdraw ETH
    function withdrawFund(uint _amount, address _recipient) public onlyOwner {
        uint balance = address(this).balance;
        if (balance < _amount) {
            _amount = balance;
        }
        payable(_recipient).transfer(_amount);
    }

    // withdarw usdt and fc
    function withdrawToken(uint _amount, address _recipient) public onlyOwner {
        uint balance = token.balanceOf(address(this));
        if (balance < _amount) {
            _amount = balance;
        }
        token.transfer(_recipient, _amount);
    }

    function setRefundable(address _user) public onlyOwner {
        UserInfo storage user = userInfo[_user];
        user.isRefundable = true;
    }

    // refund USDT for users who can't get token after presale finished
    function refundUsdt(uint _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.isRefundable, 'Not refundable');
        require(user.usdt - _amount >= 0);
        user.usdt = user.usdt - _amount;
        uint balance = token.balanceOf(address(this));
        if (balance < _amount) {
            _amount = balance;
        }
        if (_amount > 0) {
            token.transfer(msg.sender, _amount);
        }
    }

    // refund ETH for users who can't get token after presale finished
    function refundEth(uint _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.isRefundable, 'Not refundable');
        require(user.eth - _amount >= 0);
        user.eth = user.eth - _amount;
        uint balance = address(this).balance;
        if (balance < _amount) {
            _amount = balance;
        }
        if (_amount > 0) {
            payable(msg.sender).transfer(_amount);
        }
    }

    receive() external payable {}
}