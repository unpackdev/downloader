// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Decimal.sol";
import "./SafeERC20.sol";
import "./Adminable.sol";

import "./IPermittableERC20.sol";
import "./IERC20.sol";

/**
 * @notice A farm that does not require minting debt to earn rewards.
 *         Differs from LiquidityCampaign with the inclusion of
 *         `stakeWithPermit`.
 */
contract LiquidityCampaignV2 is Adminable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IPermittableERC20;

    /* ========== Structs ========== */

    struct Staker {
        uint256 balance;
        uint256 rewardPerTokenPaid;
        uint256 rewardsEarned;
        uint256 rewardsReleased;
    }

    /* ========== Variables ========== */

    IERC20 public rewardsToken;
    IPermittableERC20 public stakingToken;

    address public arcDAO;
    address public rewardsDistributor;

    mapping (address => Staker) public stakers;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    Decimal.D256 public daoAllocation;

    bool public tokensClaimable;

    uint256 public totalSupply;

    bool private _isInitialized;

    /* ========== Events ========== */

    event RewardAdded (uint256 reward);

    event Staked(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward);

    event RewardsDurationUpdated(uint256 newDuration);

    event Recovered(address token, uint256 amount);

    event ClaimableStatusUpdated(bool _status);

    /* ========== Modifiers ========== */

    modifier updateReward(address _account) {
        rewardPerTokenStored = _actualRewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (_account != address(0)) {
            stakers[_account].rewardsEarned = _actualEarned(_account);
            stakers[_account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardsDistributor() {
        require(
            msg.sender == rewardsDistributor,
            "LiquidityCampaignV2: caller is not RewardsDistributor"
        );
        _;
    }

    /* ========== Admin Functions ========== */

    function setRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyAdmin
    {
        rewardsDistributor = _rewardsDistributor;
    }

    function setRewardsDuration(
        uint256 _rewardsDuration
    )
        external
        onlyAdmin
    {
        require(
            periodFinish == 0 || currentTimestamp() > periodFinish,
            "LiquidityCampaignV2: period not finished yet"
        );

        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @notice Sets the reward amount for a period of `rewardsDuration`
     */
    function notifyRewardAmount(
        uint256 _reward
    )
        external
        onlyRewardsDistributor
        updateReward(address(0))
    {
        require(
            rewardsDuration != 0,
            "LiquidityCampaignV2: rewards duration must first be set"
        );

        if (currentTimestamp() >= periodFinish) {
            rewardRate = _reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(currentTimestamp());
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "LiquidityCampaignV2: provided reward too high"
        );

        periodFinish = currentTimestamp().add(rewardsDuration);
        lastUpdateTime = currentTimestamp();

        emit RewardAdded(_reward);
    }

    /**
     * @notice Withdraws ERC20 into the admin's account
     */
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        onlyAdmin
    {
        // Cannot recover the staking token or the rewards token
        require(
            _tokenAddress != address(stakingToken) && _tokenAddress != address(rewardsToken),
            "LiquidityCampaignV2: can't withdraw staking or rewards tokens"
        );

        IERC20(_tokenAddress).safeTransfer(getAdmin(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function setTokensClaimable(
        bool _enabled
    )
        external
        onlyAdmin
    {
        tokensClaimable = _enabled;

        emit ClaimableStatusUpdated(_enabled);
    }

    function init(
        address _arcDAO,
        address _rewardsDistributor,
        address _rewardsToken,
        address _stakingToken,
        Decimal.D256 memory _daoAllocation
    )
        public
        onlyAdmin
    {
        require(
            !_isInitialized,
            "LiquidityCampaignV2: The init function cannot be called twice"
        );

        _isInitialized = true;

        require(
            _arcDAO != address(0) &&
            _rewardsDistributor != address(0) &&
            _rewardsToken != address(0) &&
            _stakingToken != address(0) &&
            _daoAllocation.value > 0,
            "One or more parameters of init() cannot be null"
        );

        arcDAO              = _arcDAO;
        rewardsDistributor  = _rewardsDistributor;
        rewardsToken        = IERC20(_rewardsToken);
        stakingToken        = IPermittableERC20(_stakingToken);
        daoAllocation       = _daoAllocation;
    }

    /* ========== View Functions ========== */

    /**
     * @notice Returns the balance of the staker address
     */
    function balanceOf(
        address _account
    )
        public
        view
        returns (uint256)
    {
        return stakers[_account].balance;
    }

    /**
     * @notice Returns the current block timestamp if the reward period did not finish, or `periodFinish` otherwise
     */
    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return currentTimestamp() < periodFinish ? currentTimestamp() : periodFinish;
    }

    /**
     * @notice Returns the current reward amount per token staked
     */
    function _actualRewardPerToken()
        private
        view
        returns (uint256)
    {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            lastTimeRewardApplicable()
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(1e18)
                .div(totalSupply)
        );
    }

    function rewardPerToken()
        external
        view
        returns (uint256)
    {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // Since we're adding the stored amount we can't just multiply
        // the userAllocation() with the result of actualRewardPerToken()
        return
            rewardPerTokenStored.add(
                Decimal.mul(
                    lastTimeRewardApplicable()
                        .sub(lastUpdateTime)
                        .mul(rewardRate)
                        .mul(1e18)
                        .div(totalSupply),
                    userAllocation()
                )
            );
    }

    function _actualEarned(
        address _account
    )
        internal
        view
        returns (uint256)
    {
        return stakers[_account]
            .balance
            .mul(_actualRewardPerToken().sub(stakers[_account].rewardPerTokenPaid))
            .div(1e18)
            .add(stakers[_account].rewardsEarned);
    }

    function earned(
        address _account
    )
        public
        view
        returns (uint256)
    {
        return Decimal.mul(
            _actualEarned(_account),
            userAllocation()
        );
    }

    function getRewardForDuration()
        external
        view
        returns (uint256)
    {
        return rewardRate.mul(rewardsDuration);
    }

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function userAllocation()
        public
        view
        returns (Decimal.D256 memory)
    {
        return Decimal.sub(
            Decimal.one(),
            daoAllocation.value
        );
    }

    /* ========== Mutative Functions ========== */

    function stake(
        uint256 _amount
    )
        public
        updateReward(msg.sender)
    {
        // Setting each variable invididually means we don't overwrite
        Staker storage staker = stakers[msg.sender];

        staker.balance = staker.balance.add(_amount);

        totalSupply = totalSupply.add(_amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function stakeWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        stakingToken.permit(
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );
        stake(_amount);
    }

    function getReward(
        address _user
    )
        public
        updateReward(_user)
    {
        require(
            tokensClaimable == true,
            "LiquidityCampaignV2: tokens cannot be claimed yet"
        );

        Staker storage staker = stakers[_user];

        uint256 payableAmount = staker.rewardsEarned.sub(staker.rewardsReleased);

        staker.rewardsReleased = staker.rewardsReleased.add(payableAmount);

        uint256 daoPayable = Decimal.mul(payableAmount, daoAllocation);

        rewardsToken.safeTransfer(arcDAO, daoPayable);
        rewardsToken.safeTransfer(_user, payableAmount.sub(daoPayable));

        emit RewardPaid(_user, payableAmount);
    }

    function withdraw(
        uint256 _amount
    )
        public
        updateReward(msg.sender)
    {
        totalSupply = totalSupply.sub(_amount);
        stakers[msg.sender].balance = stakers[msg.sender].balance.sub(_amount);

        stakingToken.safeTransfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @notice Claim reward and withdraw collateral
     */
    function exit()
        external
    {
        getReward(msg.sender);
        withdraw(balanceOf(msg.sender));
    }
}
