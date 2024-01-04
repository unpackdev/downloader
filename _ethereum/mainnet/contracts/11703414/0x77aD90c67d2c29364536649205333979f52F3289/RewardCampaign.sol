// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Decimal.sol";
import "./Adminable.sol";

import "./IERC20.sol";

import "./IMozartCoreV1.sol";
import "./MozartTypes.sol";

contract RewardCampaign is Adminable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Structs ========== */

    struct Staker {
        uint256 positionId;
        uint256 debtSnapshot;
        uint256 balance;
        uint256 rewardPerTokenStored;
        uint256 rewardPerTokenPaid;
        uint256 rewardsEarned;
        uint256 rewardsReleased;
        address stateContract;
    }

    /* ========== Variables ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    mapping(address => bool) public approvedStateContracts;
    address[] public approvedStateContractsArray;

    address public arcDAO;
    address public rewardsDistributor;

    mapping (address => Staker) public stakers;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    Decimal.D256 public daoAllocation;
    Decimal.D256 public slasherCut;

    uint256 public vestingEndDate;
    uint256 public debtToStake;

    bool public tokensClaimable;

    uint256 private _totalSupply;

    /* ========== Events ========== */

    event RewardAdded (uint256 reward);

    event Staked(address indexed user, uint256 amount);

    event Withdrawn(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward);

    event RewardsDurationUpdated(uint256 newDuration);

    event Recovered(address token, uint256 amount);

    event PositionStaked(address _address, uint256 _positionId);

    event ClaimableStatusUpdated(bool _status);

    event UserSlashed(address _user, address _slasher, uint256 _amount);

    event StateContractApproved(address _address);

    /* ========== Modifiers ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = actualRewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            stakers[account].rewardsEarned = actualEarned(account);
            stakers[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardsDistributor() {
        require(
            msg.sender == rewardsDistributor,
            "Caller is not RewardsDistribution contract"
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
            periodFinish == 0 || getCurrentTimestamp() > periodFinish,
            "Prev period must be complete before changing duration for new period"
        );

        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function notifyRewardAmount(
        uint256 reward
    )
        external
        onlyRewardsDistributor
        updateReward(address(0))
    {
        if (getCurrentTimestamp() >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(getCurrentTimestamp());
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = getCurrentTimestamp();
        periodFinish = getCurrentTimestamp().add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    )
        public
        onlyAdmin
    {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken),
            "Cannot withdraw the staking or rewards tokens"
        );

        IERC20(tokenAddress).safeTransfer(getAdmin(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setTokensClaimable(
        bool _enabled
    )
        public
        onlyAdmin
    {
        tokensClaimable = _enabled;

        emit ClaimableStatusUpdated(_enabled);
    }

    function init(
        address _arcDAO,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        Decimal.D256 memory _daoAllocation,
        Decimal.D256 memory _slasherCut,
        uint256 _vestingEndDate,
        uint256 _debtToStake
    )
        public
        onlyAdmin
    {
        arcDAO = _arcDAO;
        rewardsDistributor = _rewardsDistribution;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);

        daoAllocation = _daoAllocation;
        slasherCut = _slasherCut;
        rewardsToken = IERC20(_rewardsToken);
        vestingEndDate = _vestingEndDate;
        debtToStake = _debtToStake;
    }

    function setApprovedStateContract(
        address _stateContract
    )
        public
        onlyAdmin
    {
        require(
            _stateContract != address(0),
            "State contract must be valid"
        );

        require(
            approvedStateContracts[_stateContract] != true,
            "The given state contract is already approved"
        );

        approvedStateContracts[_stateContract] = true;
        approvedStateContractsArray.push(_stateContract);
        emit StateContractApproved(_stateContract);
    }

    function setApprovedStateContracts(
        address[] memory _stateContracts
    )
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < _stateContracts.length; i++) {
            setApprovedStateContract(_stateContracts[i]);
        }
    }

    /* ========== View Functions ========== */

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
        return stakers[account].balance;
    }

    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return getCurrentTimestamp() < periodFinish ? getCurrentTimestamp() : periodFinish;
    }

    function actualRewardPerToken()
        internal
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function rewardPerToken()
        public
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
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
                        .div(_totalSupply),
                    userAllocation()
                )
            );
    }

    function actualEarned(
        address account
    )
        internal
        view
        returns (uint256)
    {
        return stakers[account]
            .balance
            .mul(actualRewardPerToken().sub(stakers[account].rewardPerTokenPaid))
            .div(1e18)
            .add(stakers[account].rewardsEarned);
    }

    function earned(
        address account
    )
        public
        view
        returns (uint256)
    {
        return Decimal.mul(
            actualEarned(account),
            userAllocation()
        );
    }

    function getRewardForDuration()
        public
        view
        returns (uint256)
    {
        return rewardRate.mul(rewardsDuration);
    }

    function getCurrentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function isMinter(
        address _user,
        uint256 _amount,
        uint256 _positionId,
        address _stateContract
    )
        public
        view
        returns (bool)
    {
        require(
            approvedStateContracts[_stateContract] == true,
            "The state contract is not registered"
        );

        IMozartCoreV1 stateContract = IMozartCoreV1(_stateContract);
        MozartTypes.Position memory position = stateContract.getPosition(_positionId);

        if (position.owner != _user) {
            return false;
        }

        return uint256(position.borrowedAmount.value) >= _amount;
    }

    function  userAllocation()
        public
        view
        returns (Decimal.D256 memory)
    {
        return Decimal.sub(
            Decimal.one(),
            daoAllocation.value
        );
    }

    function getAllApprovedStateContracts()
        public
        view
        returns (address[] memory)
    {
        return approvedStateContractsArray;
    }

    /* ========== Mutative Functions ========== */

    function stake(
        uint256 amount,
        uint256 positionId,
        address stateContract
    )
        external
        updateReward(msg.sender)
    {
        uint256 totalBalance = balanceOf(msg.sender).add(amount);

        // Setting each variable invididually means we don't overwrite
        Staker storage staker = stakers[msg.sender];

        require(
            staker.stateContract == address(0) || staker.stateContract == stateContract,
            "Cannot re-stake to a different state contract"
        );

        uint256 debtRequirement = totalBalance.mul(debtToStake);

        require(
            isMinter(
                msg.sender,
                debtRequirement,
                positionId,
                stateContract
            ),
            "Must be a valid minter"
        );

        // This stops an attack vector where a user stakes a lot of money
        // then drops the debt requirement by staking less before the deadline
        // to reduce the amount of debt they need to lock in

        require(
            debtRequirement >= staker.debtSnapshot,
            "Your new debt requirement cannot be lower than last time"
        );

        staker.positionId = positionId;
        staker.debtSnapshot = debtRequirement;
        staker.balance = staker.balance.add(amount);
        staker.stateContract = stateContract;

        _totalSupply = _totalSupply.add(amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function slash(
        address user
    )
        external
        updateReward(user)
    {
        require(
            user != msg.sender,
            "You cannot slash yourself"
        );

        require(
            getCurrentTimestamp() < vestingEndDate,
            "You cannot slash after the vesting end date"
        );

        Staker storage userStaker = stakers[user];

        require(
            isMinter(
                user,
                userStaker.debtSnapshot,
                userStaker.positionId,
                userStaker.stateContract
            ) == false,
            "You can't slash a user who is a valid minter"
        );

        uint256 penalty = userStaker.rewardsEarned;
        uint256 bounty = Decimal.mul(penalty, slasherCut);

        stakers[msg.sender].rewardsEarned = stakers[msg.sender].rewardsEarned.add(bounty);
        stakers[rewardsDistributor].rewardsEarned = stakers[rewardsDistributor].rewardsEarned.add(
            penalty.sub(bounty)
        );

        userStaker.rewardsEarned = 0;

        emit UserSlashed(user, msg.sender, penalty);

    }

    function getReward(address user)
        public
        updateReward(user)
    {
        require(
            tokensClaimable == true,
            "Tokens cannnot be claimed yet"
        );

        if (getCurrentTimestamp() < periodFinish) {
            // If you try to claim your reward even once the tokens are claimable
            // and the reward period is finished you'll get nothing lol.
            return;
        }

        Staker storage staker = stakers[user];

        uint256 totalAmount = staker.rewardsEarned.sub(staker.rewardsReleased);
        uint256 payableAmount = totalAmount;
        uint256 duration = vestingEndDate.sub(periodFinish);

        if (getCurrentTimestamp() < vestingEndDate) {
            payableAmount = totalAmount.mul(getCurrentTimestamp().sub(periodFinish)).div(duration);
        }

        staker.rewardsReleased = staker.rewardsReleased.add(payableAmount);

        uint256 daoPayable = Decimal.mul(payableAmount, daoAllocation);

        rewardsToken.safeTransfer(arcDAO, daoPayable);
        rewardsToken.safeTransfer(user, payableAmount.sub(daoPayable));

        emit RewardPaid(user, payableAmount);
    }

    function withdraw(
        uint256 amount
    )
        public
        updateReward(msg.sender)
    {
        require(
            amount >= 0,
            "Cannot withdraw less than 0"
        );

        _totalSupply = _totalSupply.sub(amount);
        stakers[msg.sender].balance = stakers[msg.sender].balance.sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function exit()
        public
    {
        getReward(msg.sender);
        withdraw(balanceOf(msg.sender));
    }

}
