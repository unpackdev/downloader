// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Decimal.sol";

import "./IERC20.sol";

import "./IMozartCoreV2.sol";
import "./MozartTypes.sol";

contract JointCampaign is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Structs ========== */

    struct Staker {
        uint256 positionId;
        uint256 debtSnapshot;
        uint256 balance;
        uint256 arcRewardPerTokenPaid;
        uint256 collabRewardPerTokenPaid;
        uint256 arcRewardsEarned;
        uint256 collabRewardsEarned;
        uint256 arcRewardsReleased;
        uint256 collabRewardsReleased;
    }

    /* ========== Variables ========== */

    bool public isInitialized;

    IERC20 public arcRewardToken;
    IERC20 public collabRewardToken;
    IERC20 public stakingToken;

    IMozartCoreV2 public stateContract;

    address public arcDAO;
    address public arcRewardsDistributor;
    address public collabRewardsDistributor;

    mapping (address => Staker) public stakers;

    uint256 public arcPeriodFinish = 0;
    uint256 public collabPeriodFinish = 0;
    uint256 public rewardsDuration = 0;
    uint256 public arcLastUpdateTime;
    uint256 public collabLastUpdateTime;

    uint256 public arcRewardRate = 0;
    uint256 public collabRewardRate = 0;

    uint256 public arcRewardPerTokenStored;
    uint256 public collabPerTokenStored;

    Decimal.D256 public daoAllocation;
    Decimal.D256 public slasherCut;

    uint8 public stakeToDebtRatio;

    bool public arcTokensClaimable;
    bool public collabTokensClaimable;

    uint256 private _totalSupply;

    /* ========== Events ========== */

    event RewardAdded (uint256 _reward, address _rewardToken);

    event Staked(address indexed _user, uint256 _amount);

    event Withdrawn(address indexed _user, uint256 _amount);

    event RewardPaid(address indexed _user, uint256 _arcReward, uint256 _collabReward);

    event RewardsDurationUpdated(uint256 _newDuration);

    event ERC20Recovered(address _token, uint256 _amount);

    event PositionStaked(address _address, uint256 _positionId);

    event ArcClaimableStatusUpdated(bool _status);

    event CollabClaimableStatusUpdated(bool _status);

    event UserSlashed(address _user, address _slasher, uint256 _arcPenalty, uint256 _collabPenalty);

    event CollabRewardsDistributorUpdated(address _rewardsDistributor);

    event ArcRewardsDistributorUpdated(address _rewardsDistributor);

    event CollabRecovered(uint256 _amount);

    /* ========== Modifiers ========== */

    modifier updateReward(address _account, address _rewardToken) {
        _updateReward(_account, _rewardToken);
        _;
    }

    modifier onlyRewardDistributors() {
        require(
            msg.sender == arcRewardsDistributor || msg.sender == collabRewardsDistributor,
            "Caller is not a reward distributor"
        );
        _;
    }

    modifier onlyCollabDistributor() {
        require(
            msg.sender == collabRewardsDistributor,
            "Caller is not the collab rewards distributor"
        );
        _;
    }

    modifier verifyRewardToken(address _rewardTokenAddress) {
        bool isArcToken = _rewardTokenAddress == address(arcRewardToken);
        bool iscollabToken = _rewardTokenAddress == address(collabRewardToken);

        require (
            isArcToken || iscollabToken,
            "The reward token address does not correspond to one of the rewards tokens."
        );
        _;
    }

    /* ========== Admin Functions ========== */

    function setcollabRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyCollabDistributor
    {
        require(
            collabRewardsDistributor != _rewardsDistributor,
            "Cannot set the same rewards distributor"
        );

        collabRewardsDistributor = _rewardsDistributor;
        emit CollabRewardsDistributorUpdated(_rewardsDistributor);
    }

    function setArcRewardsDistributor(
        address _rewardsDistributor
    )
        external
        onlyOwner
    {
        require(
            arcRewardsDistributor != _rewardsDistributor,
            "Cannot set the same rewards distributor"
        );

        arcRewardsDistributor = _rewardsDistributor;
        emit ArcRewardsDistributorUpdated(_rewardsDistributor);
    }

    function setRewardsDuration(
        uint256 _rewardsDuration
    )
        external
        onlyOwner
    {
        uint256 periodFinish = arcPeriodFinish > collabPeriodFinish
            ? arcPeriodFinish
            : collabPeriodFinish;

        require(
            periodFinish == 0 || getCurrentTimestamp() > periodFinish,
            "Prev period must be complete before changing duration for new period"
        );

        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @notice Sets the reward amount for the given reward token. There contract must
     *          already have at least as much amount as the given `_reward`
     *
     * @param _reward The amount of the reward
     * @param _rewardToken The address of the reward token
     */
    function notifyRewardAmount(
        uint256 _reward,
        address _rewardToken
    )
        external
        onlyRewardDistributors
        verifyRewardToken(_rewardToken)
        updateReward(address(0), _rewardToken)
    {
        require(
            rewardsDuration > 0,
            "Rewards duration is not set"
        );

        uint256 remaining;
        uint256 leftover;

        if (_rewardToken == address(arcRewardToken)) {
            require(
                msg.sender == arcRewardsDistributor,
                "Only the ARCx rewards distributor can notify the amount of ARCx rewards"
            );

            if (getCurrentTimestamp() >= arcPeriodFinish) {
                arcRewardRate = _reward.div(rewardsDuration);
            } else {
                remaining = arcPeriodFinish.sub(getCurrentTimestamp());
                leftover = remaining.mul(arcRewardRate);
                arcRewardRate = _reward.add(leftover).div(rewardsDuration);

            }

            require(
                arcRewardRate <= arcRewardToken.balanceOf(address(this)).div(rewardsDuration),
                "Provided reward too high for the balance of ARCx token"
            );

            arcPeriodFinish = getCurrentTimestamp().add(rewardsDuration);
            arcLastUpdateTime = getCurrentTimestamp();
        } else {
            require(
                msg.sender == collabRewardsDistributor,
                "Only the collab rewards distributor can notify the amount of collab rewards"
            );

            // collab token
            if (getCurrentTimestamp() >= collabPeriodFinish) {
                collabRewardRate = _reward.div(rewardsDuration);
            } else {
                remaining = collabPeriodFinish.sub(getCurrentTimestamp());
                leftover = remaining.mul(collabRewardRate);
                collabRewardRate = _reward.add(leftover).div(rewardsDuration);

            }

            require(
                collabRewardRate <= collabRewardToken.balanceOf(address(this)).div(rewardsDuration),
                "Provided reward too high for the balance of collab token"
            );

            collabPeriodFinish = getCurrentTimestamp().add(rewardsDuration);
            collabLastUpdateTime = getCurrentTimestamp();
        }

        emit RewardAdded(_reward, _rewardToken);
    }

    /**
     * @notice Allows owner to recover any ERC20 token sent to this contract, except the staking
     *          okens and the reward tokens - with the exception of ARCx surplus that was transfered.
     *
     * @param _tokenAddress the address of the token
     * @param _tokenAmount to amount to recover
     */
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    )
        external
        onlyOwner
    {
        // If _tokenAddress is ARCx, only allow its recovery if the amount is not greater than
        // the current reward
        if (_tokenAddress == address(arcRewardToken) && rewardsDuration > 0) {
            uint256 arcBalance = arcRewardToken.balanceOf(address(this));

            require(
                arcRewardRate <= arcBalance.sub(_tokenAmount).div(rewardsDuration),
                "Only the surplus of the reward can be recovered, not more"
            );
        }

        // Cannot recover the staking token or the collab rewards token
        require(
            _tokenAddress != address(stakingToken) && _tokenAddress != address(collabRewardToken),
            "Cannot withdraw the staking or collab reward tokens"
        );

        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit ERC20Recovered(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice Lets the collab reward distributor recover a desired amount of collab as long as that
     *          amount is not greater than the reward to recover
     *
     * @param _amount The amount of collab to recover
     */
    function recovercollab(
        uint256 _amount
    )
        external
        onlyCollabDistributor
    {
        if (rewardsDuration > 0) {
            uint256 collabBalance = collabRewardToken.balanceOf(address(this));

            require(
                collabRewardRate <= collabBalance.sub(_amount).div(rewardsDuration),
                "Only the surplus of the reward can be recovered, not more"
            );
        }

        collabRewardToken.safeTransfer(msg.sender, _amount);
        emit CollabRecovered(_amount);
    }

    function setArcTokensClaimable(
        bool _enabled
    )
        external
        onlyOwner
    {
        arcTokensClaimable = _enabled;

        emit ArcClaimableStatusUpdated(_enabled);
    }

    function setCollabTokensClaimable(
        bool _enabled
    )
        external
        onlyOwner
    {
        collabTokensClaimable = _enabled;

        emit CollabClaimableStatusUpdated(_enabled);
    }

    function init(
        address _arcDAO,
        address _arcRewardsDistributor,
        address _collabRewardsDistributor,
        address _arcRewardToken,
        address _collabRewardToken,
        address _stakingToken,
        Decimal.D256 memory _daoAllocation,
        Decimal.D256 memory _slasherCut,
        uint8 _stakeToDebtRatio,
        address _stateContract
    )
        public
        onlyOwner
    {
        require(
            !isInitialized &&
            _arcDAO != address(0) &&
            _arcRewardsDistributor != address(0) &&
            _collabRewardsDistributor != address(0) &&
            _arcRewardToken != address(0) &&
            _collabRewardToken != address(0) &&
            _stakingToken != address(0) &&
            _daoAllocation.value > 0 &&
            _slasherCut.value > 0 &&
            _stakeToDebtRatio > 0 &&
            _stateContract != address(0),
            "One or more values is empty"
        );

        isInitialized = true;

        arcDAO = _arcDAO;
        arcRewardsDistributor = _arcRewardsDistributor;
        collabRewardsDistributor = _collabRewardsDistributor;
        arcRewardToken = IERC20(_arcRewardToken);
        collabRewardToken = IERC20(_collabRewardToken);
        stakingToken = IERC20(_stakingToken);

        daoAllocation = _daoAllocation;
        slasherCut = _slasherCut;
        stakeToDebtRatio = _stakeToDebtRatio;

        stateContract = IMozartCoreV2(_stateContract);
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

    function lastTimeRewardApplicable(
        address _rewardToken
    )
        public
        view
        verifyRewardToken(_rewardToken)
        returns (uint256)
    {
        uint256 relevantPeriod = _rewardToken == address(arcRewardToken) ? arcPeriodFinish : collabPeriodFinish;

        return getCurrentTimestamp() < relevantPeriod ? getCurrentTimestamp() : relevantPeriod;
    }

    function arcRewardPerTokenUser()
        external
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return arcRewardPerTokenStored;
        }

        return
            Decimal.mul(
                arcRewardPerTokenStored.add(
                    lastTimeRewardApplicable(address(arcRewardToken))
                        .sub(arcLastUpdateTime)
                        .mul(arcRewardRate)
                        .mul(1e18)
                        .div(_totalSupply)
                ),
                userAllocation()
            );
    }

    function collabRewardPerToken()
        external
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return collabPerTokenStored;
        }

        return collabPerTokenStored.add(
            lastTimeRewardApplicable(address(collabRewardToken))
                .sub(collabLastUpdateTime)
                .mul(collabRewardRate)
                .mul(1e18)
                .div(_totalSupply)
        );
    }

    function _actualEarned(
        address _account,
        address _rewardTokenAddress
    )
        internal
        view
        verifyRewardToken(_rewardTokenAddress)
        returns (uint256)
    {
        uint256 stakerBalance = stakers[_account].balance;

        if (_rewardTokenAddress == address(arcRewardToken)) {
            return
                stakerBalance.mul(
                    _rewardPerToken(address(arcRewardToken))
                    .sub(stakers[_account].arcRewardPerTokenPaid)
                )
                .div(1e18)
                .add(stakers[_account].arcRewardsEarned);
        }

        return
            stakerBalance.mul(
                _rewardPerToken(address(collabRewardToken))
                .sub(stakers[_account].collabRewardPerTokenPaid)
            )
            .div(1e18)
            .add(stakers[_account].collabRewardsEarned);
    }

    function arcEarned(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return Decimal.mul(
            _actualEarned(_account, address(arcRewardToken)),
            userAllocation()
        );
    }

    function collabEarned(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return _actualEarned(_account, address(collabRewardToken));
    }

    function getArcRewardForDuration()
        external
        view
        returns (uint256)
    {
        return arcRewardRate.mul(rewardsDuration);
    }

    function getCollabRewardForDuration()
        external
        view
        returns (uint256)
    {
        return collabRewardRate.mul(rewardsDuration);
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
        uint256 _positionId
    )
        public
        view
        returns (bool)
    {
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

    /* ========== Mutative Functions ========== */

    function stake(
        uint256 _amount,
        uint256 _positionId
    )
        external
        updateReward(msg.sender, address(0))
    {
        uint256 totalBalance = balanceOf(msg.sender).add(_amount);

        // Setting each variable invididually means we don't overwrite
        Staker storage staker = stakers[msg.sender];

        if (staker.positionId != 0) {
            require (
                staker.positionId == _positionId,
                "You cannot stake based on a different debt position"
            );
        }

        require(
            stakeToDebtRatio != 0,
            "The stake to debt ratio cannot be 0"
        );

        uint256 debtRequirement = totalBalance.div(uint256(stakeToDebtRatio));

        require(
            isMinter(
                msg.sender,
                debtRequirement,
                _positionId
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

        if (staker.positionId == 0) {
            staker.positionId = _positionId;
        }
        staker.debtSnapshot = debtRequirement;
        staker.balance = staker.balance.add(_amount);

        _totalSupply = _totalSupply.add(_amount);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function slash(
        address _user
    )
        external
        updateReward(_user, address(0))
    {
        require(
            _user != msg.sender,
            "You cannot slash yourself"
        );

        uint256 currentTime = getCurrentTimestamp();
        require(
            currentTime < arcPeriodFinish ||
            currentTime < collabPeriodFinish,
            "You cannot slash after the reward period"
        );

        Staker storage userStaker = stakers[_user];

        require(
            isMinter(
                _user,
                userStaker.debtSnapshot,
                userStaker.positionId
            ) == false,
            "You can't slash a user who is a valid minter"
        );

        uint256 arcPenalty = userStaker.arcRewardsEarned.sub(userStaker.arcRewardsReleased);
        uint256 arcBounty = Decimal.mul(arcPenalty, slasherCut);

        uint256 collabPenalty = userStaker.collabRewardsEarned.sub(userStaker.collabRewardsReleased);

        stakers[msg.sender].arcRewardsEarned = stakers[msg.sender].arcRewardsEarned.add(arcBounty);
        stakers[msg.sender].collabRewardsEarned = stakers[msg.sender].collabRewardsEarned.add(collabPenalty);

        stakers[arcRewardsDistributor].arcRewardsEarned = stakers[arcRewardsDistributor].arcRewardsEarned.add(
            arcPenalty.sub(arcBounty)
        );

        userStaker.arcRewardsEarned = userStaker.arcRewardsEarned.sub(arcPenalty);
        userStaker.collabRewardsEarned = userStaker.collabRewardsEarned.sub(collabPenalty);

        emit UserSlashed(
            _user,
            msg.sender,
            arcPenalty,
            collabPenalty
        );
    }

    function getReward(address _user)
        public
        updateReward(_user, address(0))
    {
        Staker storage staker = stakers[_user];
        uint256 arcPayableAmount;
        uint256 collabPayableAmount;

        require(
            collabTokensClaimable || arcTokensClaimable,
            "At least one reward token must be claimable"
        );

        if (collabTokensClaimable) {
            collabPayableAmount = staker.collabRewardsEarned.sub(staker.collabRewardsReleased);
            staker.collabRewardsReleased = staker.collabRewardsReleased.add(collabPayableAmount);

            collabRewardToken.safeTransfer(_user, collabPayableAmount);
        }

        if (arcTokensClaimable) {
            arcPayableAmount = staker.arcRewardsEarned.sub(staker.arcRewardsReleased);
            staker.arcRewardsReleased = staker.arcRewardsReleased.add(arcPayableAmount);

            uint256 daoPayable = Decimal.mul(arcPayableAmount, daoAllocation);
            arcRewardToken.safeTransfer(arcDAO, daoPayable);
            arcRewardToken.safeTransfer(_user, arcPayableAmount.sub(daoPayable));
        }

        emit RewardPaid(_user, arcPayableAmount, collabPayableAmount);
    }

    function withdraw(
        uint256 amount
    )
        public
        updateReward(msg.sender, address(0))
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
        external
    {
        getReward(msg.sender);
        withdraw(balanceOf(msg.sender));
    }

    /* ========== Private Functions ========== */

    function _updateReward(
        address _account,
        address _rewardToken
    )
        private
    {
        require(
            _rewardToken == address(0) ||
            _rewardToken == address(arcRewardToken) ||
            _rewardToken == address(collabRewardToken),
            "The reward token can either be 0 or a valid reward token"
        );

        // If an individual reward token is updated, only update the relevant variables
        if (_rewardToken == address(0)) {
            arcRewardPerTokenStored = _rewardPerToken(address(arcRewardToken));
            collabPerTokenStored = _rewardPerToken(address(collabRewardToken));

            arcLastUpdateTime = lastTimeRewardApplicable(address(arcRewardToken));
            collabLastUpdateTime = lastTimeRewardApplicable(address(collabRewardToken));

        } else if (_rewardToken == address(arcRewardToken)) {
            arcRewardPerTokenStored = _rewardPerToken(address(arcRewardToken));
            arcLastUpdateTime = lastTimeRewardApplicable(address(arcRewardToken));

        } else {
            collabPerTokenStored = _rewardPerToken(address(collabRewardToken));
            collabLastUpdateTime = lastTimeRewardApplicable(address(collabRewardToken));
        }

        if (_account != address(0)) {
            stakers[_account].arcRewardsEarned = _actualEarned(_account, address(arcRewardToken));
            stakers[_account].arcRewardPerTokenPaid = arcRewardPerTokenStored;

            stakers[_account].collabRewardsEarned = _actualEarned(_account, address(collabRewardToken));
            stakers[_account].collabRewardPerTokenPaid = collabPerTokenStored;
        }
    }

    function _rewardPerToken(
        address _rewardTokenAddress
    )
        private
        view
        verifyRewardToken(_rewardTokenAddress)
        returns (uint256)
    {
        if (_rewardTokenAddress == address(arcRewardToken)) {
            if (_totalSupply == 0) {
                return arcRewardPerTokenStored;
            }

            return arcRewardPerTokenStored.add(
                lastTimeRewardApplicable(address(arcRewardToken))
                    .sub(arcLastUpdateTime)
                    .mul(arcRewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
        } else {
            if (_totalSupply == 0) {
                return collabPerTokenStored;
            }

            return collabPerTokenStored.add(
                lastTimeRewardApplicable(address(collabRewardToken))
                    .sub(collabLastUpdateTime)
                    .mul(collabRewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
        }
    }


}
