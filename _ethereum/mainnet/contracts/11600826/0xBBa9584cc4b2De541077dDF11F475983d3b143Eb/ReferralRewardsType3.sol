pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

interface IMintableBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address _to, uint256 _amount) external;
}

interface IReferralRewards {
    struct DepositInfo {
        address referrer;
        uint256 depth;
        uint256 amount;
        uint256 time;
        uint256 lastUpdatedTime;
    }
    struct ReferralInfo {
        uint256 reward;
        uint256 lastUpdate;
        uint256 depositHead;
        uint256 depositTail;
        uint256[3] amounts;
        mapping(uint256 => DepositInfo) deposits;
    }

    function setBounds(uint256[3] calldata _depositBounds) external;

    function setDepositRate(uint256[3][3] calldata _depositRate) external;

    function setStakingRate(uint256[3][3] calldata _stakingRate) external;

    function assessReferalDepositReward(address _referrer, uint256 _amount)
        external;

    function claimDividends() external;

    function claimAllDividends(address _referral) external;

    function removeDepositReward(address _referrer, uint256 _amount) external;

    function getReferralReward(address _user) external view;

    function getReferral(address _user) external view returns (address);

    function getStakingRateRange(uint256 _referralStake)
        external
        view
        returns (uint256[3] memory _rates);

    function getDepositRate(uint256[] calldata _referralStakes)
        external
        view
        returns (uint256[] memory _rates);

    function getDepositBounds() external view returns (uint256[3] memory);

    function getStakingRates() external view returns (uint256[3][3] memory);

    function getDepositRates() external view returns (uint256[3][3] memory);

    function getReferralAmounts(address _user)
        external
        view
        returns (uint256[3] memory);
}

interface IReferralTree {
    function changeAdmin(address _newAdmin) external;

    function setReferral(address _referrer, address _referral) external;

    function removeReferralReward(IReferralRewards _referralRewards) external;

    function addReferralReward(IReferralRewards _referralRewards) external;

    function claimAllDividends() external;

    function getReferrals(address _referrer, uint256 _referDepth)
        external
        view
        returns (address[] memory);

    function referrals(address _referrer) external view returns (address);

    function getReferrers(address _referral)
        external
        view
        returns (address[] memory);

    function getUserReferralReward(address _user)
        external
        view
        returns (uint256);

    function getReferralRewards()
        external
        view
        returns (IReferralRewards[] memory);
}

interface IRewards {
    struct DepositInfo {
        uint256 amount;
        uint256 time;
    }

    struct UserInfo {
        uint256 amount;
        uint256 unfrozen;
        uint256 reward;
        uint256 lastUpdate;
        uint256 depositHead;
        uint256 depositTail;
        mapping(uint256 => DepositInfo) deposits;
    }

    function setActive(bool _isActive) external;

    function setReferralRewards(IReferralRewards _referralRewards) external;

    function setDuration(uint256 _duration) external;

    function setRewardPerSec(uint256 _rewardPerSec) external;

    function stakeFor(address _user, uint256 _amount) external;

    function stake(uint256 _amount, address _refferal) external;

    function getPendingReward(address _user, bool _includeDeposit)
        external
        view
        returns (uint256 _reward);

    function getReward(address _user) external view returns (uint256 _reward);

    function getReferralStakes(address[] calldata _referrals)
        external
        view
        returns (uint256[] memory _stakes);

    function getReferralStake(address _referral)
        external
        view
        returns (uint256);

    function getEstimated(uint256 _delta) external view returns (uint256);

    function getDeposit(address _user, uint256 _id)
        external
        view
        returns (uint256, uint256);
}

interface IRewardsV2 {
    struct DepositInfo {
        uint256 amount;
        uint256 time;
    }

    struct UserInfo {
        uint256 amount;
        uint256 unfrozen;
        uint256 reward;
        uint256 lastUpdate;
        uint256 depositHead;
        uint256 depositTail;
        mapping(uint256 => DepositInfo) deposits;
    }

    function setActive(bool _isActive) external;

    function setReferralRewards(IReferralRewards _referralRewards) external;

    function setDuration(uint256 _duration) external;

    function setRewardPerSec(uint256 _rewardPerSec) external;

    function stakeFor(address _user, uint256 _amount) external;

    function stake(uint256 _amount, address _refferal) external;

    function getPendingReward(address _user, bool _includeDeposit)
        external
        view
        returns (uint256 _reward);

    function rewardPerSec() external view returns (uint256);

    function getReward(address _user) external view returns (uint256 _reward);

    function getReferralStake(address _referral)
        external
        view
        returns (uint256);

    function getEstimated(uint256 _delta) external view returns (uint256);

    function getDeposit(address _user, uint256 _id)
        external
        view
        returns (uint256, uint256);
}

contract ReferralRewardsV2 is Ownable {
    using SafeMath for uint256;

    event ReferralDepositReward(
        address indexed refferer,
        address indexed refferal,
        uint256 indexed level,
        uint256 amount
    );
    event ReferralRewardPaid(address indexed user, uint256 amount);

    // Info of each referral
    struct ReferralInfo {
        uint256 totalDeposit; // Ammount of own deposits
        uint256 reward; // Ammount of collected deposit rewardsV2
        uint256 lastUpdate; // Last time the referral claimed rewardsV2
        uint256[amtLevels] amounts; // Amounts that generate rewardsV2 on each referral level
    }

    uint256 public constant amtLevels = 3; // Number of levels by total staked amount that determine referral reward's rate
    uint256 public constant referDepth = 3; // Number of referral levels that can receive dividends

    IMintableBurnableERC20 public token; // Harvested token contract
    IReferralTree public referralTree; // Contract with referral's tree
    IRewardsV2 rewardsV2; // Main farming contract
    IRewards rewards; // Main farming contract

    uint256[amtLevels] public depositBounds; // Limits of referral's stake used to determine the referral rate
    uint256[referDepth][amtLevels] public depositRate; // Referral rates based on referral's deplth and stake received from deposit
    uint256[referDepth][amtLevels] public stakingRate; // Referral rates based on referral's deplth and stake received from staking

    mapping(address => ReferralInfo) public referralReward; // Info per each referral

    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    /// @param _rewards Main farming contract.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    constructor(
        IMintableBurnableERC20 _token,
        IReferralTree _referralTree,
        IRewards _rewards,
        IRewardsV2 _rewardsV2,
        uint256[amtLevels] memory _depositBounds,
        uint256[referDepth][amtLevels] memory _depositRate,
        uint256[referDepth][amtLevels] memory _stakingRate
    ) public Ownable() {
        token = _token;
        referralTree = _referralTree;
        depositBounds = _depositBounds;
        depositRate = _depositRate;
        stakingRate = _stakingRate;
        rewardsV2 = _rewardsV2;
        rewards = _rewards;
    }

    /// @dev Allows an owner to update bounds.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    function setBounds(uint256[amtLevels] memory _depositBounds)
        public
        onlyOwner
    {
        depositBounds = _depositBounds;
    }

    /// @dev Allows an owner to update deposit rates.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    function setDepositRate(uint256[referDepth][amtLevels] memory _depositRate)
        public
        onlyOwner
    {
        depositRate = _depositRate;
    }

    /// @dev Allows an owner to update staking rates.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    function setStakingRate(uint256[referDepth][amtLevels] memory _stakingRate)
        public
        onlyOwner
    {
        stakingRate = _stakingRate;
    }

    /// @dev Allows the main farming contract to assess referral deposit rewardsV2.
    /// @param _referrer Address of the referred user.
    /// @param _referral Address of the user.
    /// @param _amount Amount of new deposit.
    function proccessDeposit(
        address _referrer,
        address _referral,
        uint256 _amount
    ) external virtual {
        require(
            msg.sender == address(rewardsV2),
            "assessReferalDepositReward: bad role"
        );
        referralTree.setReferral(_referrer, _referral);
        referralReward[_referrer].totalDeposit = referralReward[_referrer]
            .totalDeposit
            .add(_amount);
        address[] memory referrals =
            referralTree.getReferrals(_referrer, referDepth);
        uint256[] memory referralStakes = rewards.getReferralStakes(referrals);
        for (uint256 level = 0; level < referrals.length; level++) {
            if (referrals[level] == address(0)) {
                continue;
            }
            accumulateReward(referrals[level]);
            ReferralInfo storage referralInfo =
                referralReward[referrals[level]];
            referralInfo.amounts[level] = referralInfo.amounts[level].add(
                _amount
            );
            uint256 percent =
                getDepositRate(
                    referralInfo.totalDeposit.add(referralStakes[level]),
                    level
                );
            if (percent == 0) {
                continue;
            }
            uint256 depositReward = _amount.mul(percent);
            if (depositReward > 0) {
                referralInfo.reward = referralInfo.reward.add(depositReward);
                emit ReferralDepositReward(
                    _referrer,
                    referrals[level],
                    level,
                    depositReward
                );
            }
        }
    }

    /// @dev Allows the main farming contract to assess referral deposit rewardsV2.
    /// @param _referrer Address of the referred user.
    /// @param _amount Amount of new deposit.
    function handleDepositEnd(address _referrer, uint256 _amount)
        external
        virtual
    {
        require(msg.sender == address(rewardsV2), "handleDepositEnd: bad role");
        referralReward[_referrer].totalDeposit = referralReward[_referrer]
            .totalDeposit
            .sub(_amount);
        address[] memory referrals =
            referralTree.getReferrals(_referrer, referDepth);
        for (uint256 level = 0; level < referrals.length; level++) {
            if (referrals[level] == address(0)) {
                continue;
            }
            accumulateReward(referrals[level]);
            ReferralInfo storage referralInfo =
                referralReward[referrals[level]];
            referralInfo.amounts[level] = referralInfo.amounts[level].sub(
                _amount
            );
        }
    }

    /// @dev Allows a user to claim his dividends.
    function claimDividends() public {
        claimUserDividends(msg.sender);
    }

    /// @dev Allows a referral tree to claim all the dividends.
    /// @param _referral Address of user that claims his dividends.
    function claimAllDividends(address _referral) public {
        require(
            msg.sender == address(referralTree),
            "claimAllDividends: bad role"
        );
        claimUserDividends(_referral);
    }

    /// @dev Update the staking referral reward for _user.
    /// @param _user Address of the referral.
    function accumulateReward(address _user) internal {
        ReferralInfo storage referralInfo = referralReward[_user];
        if (referralInfo.lastUpdate > now) {
            return;
        }
        uint256 rewardPerSec = rewardsV2.rewardPerSec();
        uint256 referralPrevStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates =
            getStakingRateRange(
                referralInfo.totalDeposit.add(referralPrevStake)
            );
        if (referralInfo.lastUpdate > 0) {
            for (uint256 i = 0; i < referralInfo.amounts.length; i++) {
                uint256 reward =
                    now
                        .sub(referralInfo.lastUpdate)
                        .mul(referralInfo.amounts[i])
                        .mul(rewardPerSec)
                        .mul(rates[i])
                        .div(1e18);
                if (reward > 0) {
                    referralInfo.reward = referralInfo.reward.add(reward);
                }
            }
        }
        referralInfo.lastUpdate = now;
    }

    /// @dev Asses and distribute claimed dividends.
    /// @param _user Address of user that claims dividends.
    function claimUserDividends(address _user) internal {
        accumulateReward(_user);
        ReferralInfo storage referralInfo = referralReward[_user];
        uint256 amount = referralInfo.reward.div(1e18);
        if (amount > 0) {
            uint256 scaledReward = amount.mul(1e18);
            referralInfo.reward = referralInfo.reward.sub(scaledReward);
            token.mint(_user, amount);
            emit ReferralRewardPaid(_user, amount);
        }
    }

    /// @dev Returns referral reward.
    /// @param _user Address of referral.
    /// @return Referral reward.
    function getReferralReward(address _user) external view returns (uint256) {
        ReferralInfo storage referralInfo = referralReward[_user];
        uint256 rewardPerSec = rewardsV2.rewardPerSec();
        uint256 referralPrevStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates =
            getStakingRateRange(
                referralInfo.totalDeposit.add(referralPrevStake)
            );
        uint256 _reward = referralInfo.reward;
        if (referralInfo.lastUpdate > 0) {
            for (uint256 i = 0; i < referralInfo.amounts.length; i++) {
                _reward = _reward.add(
                    now
                        .sub(referralInfo.lastUpdate)
                        .mul(referralInfo.amounts[i])
                        .mul(rewardPerSec)
                        .mul(rates[i])
                        .div(1e18)
                );
            }
        }
        return _reward.div(1e18);
    }

    /// @dev Returns direct user referral.
    /// @param _user Address of referrer.
    /// @return Direct user referral.
    function getReferral(address _user) public view returns (address) {
        return referralTree.referrals(_user);
    }

    /// @dev Returns stakong rate for the spesific referral stake.
    /// @param _referralStake Amount staked by referral.
    /// @return _rates Array of stakong rates by referral level.
    function getStakingRateRange(uint256 _referralStake)
        public
        view
        returns (uint256[referDepth] memory _rates)
    {
        for (uint256 i = 0; i < depositBounds.length; i++) {
            if (_referralStake >= depositBounds[i]) {
                return stakingRate[i];
            }
        }
    }

    /// @dev Returns deposit rate based on the spesific referral stake and referral level.
    /// @param _referralStake Amount staked by referrals.
    /// @param _level Level of the referral.
    /// @return _rate Deposit rates by referral level.
    function getDepositRate(uint256 _referralStake, uint256 _level)
        public
        view
        returns (uint256 _rate)
    {
        for (uint256 j = 0; j < depositBounds.length; j++) {
            if (_referralStake >= depositBounds[j]) {
                return depositRate[j][_level];
            }
        }
    }

    /// @dev Returns limits of referral's stake used to determine the referral rate.
    /// @return Array of deposit bounds.
    function getDepositBounds()
        public
        view
        returns (uint256[referDepth] memory)
    {
        return depositBounds;
    }

    /// @dev Returns referral rates based on referral's deplth and stake received from staking.
    /// @return Array of staking rates.
    function getStakingRates()
        public
        view
        returns (uint256[referDepth][amtLevels] memory)
    {
        return stakingRate;
    }

    /// @dev Returns referral rates based on referral's deplth and stake received from deposit.
    /// @return Array of deposit rates.
    function getDepositRates()
        public
        view
        returns (uint256[referDepth][amtLevels] memory)
    {
        return depositRate;
    }

    /// @dev Returns amounts that generate reward for referral bu levels.
    /// @param _user Address of referral.
    /// @return Returns amounts that generate reward for referral bu levels.
    function getReferralAmounts(address _user)
        public
        view
        returns (uint256[amtLevels] memory)
    {
        ReferralInfo memory referralInfo = referralReward[_user];
        return referralInfo.amounts;
    }
}
contract ReferralRewardsType3 is ReferralRewardsV2 {
    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    /// @param _rewards Old farming contract.
    /// @param _rewardsV2 Main farming contract.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    constructor(
        IMintableBurnableERC20 _token,
        IReferralTree _referralTree,
        IRewards _rewards,
        IRewardsV2 _rewardsV2,
        uint256[amtLevels] memory _depositBounds,
        uint256[referDepth][amtLevels] memory _depositRate,
        uint256[referDepth][amtLevels] memory _stakingRate
    )
        public
        ReferralRewardsV2(
            _token,
            _referralTree,
            _rewards,
            _rewardsV2,
            _depositBounds,
            _depositRate,
            _stakingRate
        )
    {}
}