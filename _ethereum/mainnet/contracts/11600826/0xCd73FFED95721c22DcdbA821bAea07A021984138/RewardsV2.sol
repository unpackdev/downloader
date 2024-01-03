pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./IMintableBurnableERC20.sol";
import "./IReferralRewardsV2.sol";

abstract contract RewardsV2 is Ownable {
    using SafeMath for uint256;

    event Deposit(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 start,
        uint256 end
    );
    event Withdraw(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 ended,
        uint256 time
    );
    event RewardPaid(address indexed user, uint256 amount);

    // Info of each deposit made by the user
    struct DepositInfo {
        uint256 amount; // Amount of deposited LP tokens
        uint256 time; // Wnen the deposit is ended
    }

    // Info of each user
    struct UserInfo {
        uint256 amount; // Total deposited amount
        uint256 unfrozen; // Amount of token to be unstaked
        uint256 reward; // Ammount of claimed rewards
        uint256 claimable; // Ammount of claimable rewards
        uint256 lastUpdate; // Last time the user claimed rewards
        uint256 depositHead; // The start index in the deposit's list
        uint256 depositTail; // The end index in the deposit's list
        mapping(uint256 => DepositInfo) deposits; // User's dposits
    }

    IMintableBurnableERC20 public token; // Harvested token contract
    IReferralRewardsV2 public referralRewards; // Contract that manages referral rewards

    uint256 public duration; // How long the deposit works
    uint256 public rewardPerSec; // Reward rate generated each second
    uint256 public totalStake; // Amount of all staked LP tokens
    uint256 public totalClaimed; // Amount of all distributed rewards
    uint256 public lastUpdate; // Last time someone received rewards

    bool public isActive; // If the deposits are allowed

    mapping(address => UserInfo) public userInfo; // Info per each user

    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _duration How long the deposit works.
    /// @param _rewardPerSec Reward rate generated each second.
    constructor(
        IMintableBurnableERC20 _token,
        uint256 _duration,
        uint256 _rewardPerSec
    ) public Ownable() {
        token = _token;
        duration = _duration;
        rewardPerSec = _rewardPerSec;
        isActive = true;
    }

    /// @dev Allows an owner to stop or countinue deposits.
    /// @param _isActive Whether the deposits are allowed.
    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    /// @dev Allows an owner to update referral rewardsV2 module.
    /// @param _referralRewards Contract that manages referral rewardsV2.
    function setReferralRewards(IReferralRewardsV2 _referralRewards)
        public
        onlyOwner
    {
        referralRewards = _referralRewards;
    }

    /// @dev Allows an owner to update duration of the deposits.
    /// @param _duration How long the deposit works.
    function setDuration(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    /// @dev Allows an owner to update reward rate per sec.
    /// @param _rewardPerSec Reward rate generated each second.
    function setRewardPerSec(uint256 _rewardPerSec) public onlyOwner {
        rewardPerSec = _rewardPerSec;
    }

    /// @dev Allows to stake for the specific user.
    /// @param _user Deposit receiver.
    /// @param _amount Amount of deposit.
    function stakeFor(address _user, uint256 _amount) public {
        require(
            referralRewards.getReferral(_user) != address(0),
            "stakeFor: referral isn't set"
        );
        proccessStake(_user, _amount, address(0), 0);
    }

    /// @dev Allows to stake for themselves.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    /// @param _reinvest Whether the tokens should be reinvested.
    function stake(
        uint256 _amount,
        address _refferal,
        uint256 _reinvest
    ) public {
        proccessStake(msg.sender, _amount, _refferal, _reinvest);
    }

    /// @dev Allows to stake for themselves.
    /// @param _count Max amount of claimed deposits.
    function claimDeposits(uint256 _count) public {
        executeUnstakes(msg.sender, _count);
    }

    /// @dev Allows to stake for themselves.
    /// @param _amount Max amount of claimed deposits.
    function claim(uint256 _amount) public {
        updateStakingReward(msg.sender);
        proccessClaim(msg.sender, _amount, false);
    }

    /// @dev Proccess the stake.
    /// @param _receiver Deposit receiver.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    /// @param _reinvest Whether the tokens should be reinvested.
    function proccessStake(
        address _receiver,
        uint256 _amount,
        address _refferal,
        uint256 _reinvest
    ) internal virtual {
        require(isActive, "stake: is paused");
        updateStakingReward(_receiver);
        if (_amount > 0) {
            token.transferFrom(msg.sender, address(this), _amount);
            addDeposit(_receiver, _amount, _refferal);
        }
        if (_reinvest > 0) {
            proccessClaim(_receiver, _reinvest, true);
        }
    }

    /// @dev Proccess the stake.
    /// @param _receiver Deposit receiver.
    /// @param _amount Amount of deposit.
    /// @param _reinvest Whether the tokens should be reinvested.
    function proccessClaim(
        address _receiver,
        uint256 _amount,
        bool _reinvest
    ) internal virtual {
        UserInfo storage user = userInfo[_receiver];
        if (_amount == 0) {
            _amount = user.claimable;
        }
        require(user.claimable >= _amount, "claim: insufficient rewards");
        user.claimable = user.claimable.sub(_amount);
        user.reward = user.reward.add(_amount);
        totalClaimed = totalClaimed.add(_amount);
        emit RewardPaid(_receiver, _amount);
        if (_reinvest) {
            token.mint(address(this), _amount);
            addDeposit(_receiver, _amount, address(0));
        } else {
            token.mint(_receiver, _amount);
        }
    }

    /// @dev Assess new reward.
    /// @param _user Address of the user.
    function updateStakingReward(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.lastUpdate >= now) {
            return;
        }
        uint256 scaledReward =
            now.sub(user.lastUpdate).mul(user.amount).mul(rewardPerSec);
        uint256 reward = scaledReward.div(1e18);
        lastUpdate = now;
        user.claimable = user.claimable.add(reward);
        user.lastUpdate = now;
    }

    /// @dev Add the deposit.
    /// @param _receiver Deposit receiver.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    function addDeposit(
        address _receiver,
        uint256 _amount,
        address _refferal
    ) internal virtual {
        UserInfo storage user = userInfo[_receiver];
        user.amount = user.amount.add(_amount);
        totalStake = totalStake.add(_amount);
        user.deposits[user.depositTail] = DepositInfo({
            amount: _amount,
            time: now + duration
        });
        emit Deposit(_receiver, user.depositTail, _amount, now, now + duration);
        user.depositTail = user.depositTail.add(1);
        referralRewards.proccessDeposit(_receiver, _refferal, _amount);
    }

    /// @dev Accumulate new reward and remove old deposits.
    /// @param _user Address of the user.
    /// @param _count How many deposits to claim.
    function executeUnstakes(address _user, uint256 _count) internal virtual {
        UserInfo storage user = userInfo[_user];
        _count = (_count == 0)
            ? user.depositTail
            : Math.min(user.depositTail, user.depositHead.add(_count));
        uint256 endedDepositAmount = 0;
        for (uint256 i = user.depositHead; i < _count; i++) {
            DepositInfo memory deposit = user.deposits[i];
            if (deposit.time < now) {
                endedDepositAmount = endedDepositAmount.add(deposit.amount);
                delete user.deposits[i];
                user.depositHead = user.depositHead.add(1);
                emit Withdraw(_user, 0, deposit.amount, deposit.time, now);
            }
        }
        if (endedDepositAmount > 0) {
            user.amount = user.amount.sub(endedDepositAmount);
            totalStake = totalStake.sub(endedDepositAmount);
            referralRewards.handleDepositEnd(_user, endedDepositAmount);
            safeTokenTransfer(_user, endedDepositAmount);
        }
    }

    /// @dev Safe token transfer.
    /// @param _to Address of the receiver.
    /// @param _amount Amount of the tokens to be sent.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    /// @dev Returns user's unclaimed reward.
    /// @param _user Address of the user.
    /// @param _includeDeposit Should the finnished deposits be included into calculations.
    /// @return _reward User's reward.
    function getPendingReward(address _user, bool _includeDeposit)
        public
        view
        virtual
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = user.claimable.add(
            now.sub(user.lastUpdate).mul(user.amount).mul(rewardPerSec).div(
                1e18
            )
        );
        if (_includeDeposit) {
            for (uint256 i = user.depositHead; i < user.depositTail; i++) {
                DepositInfo memory deposit = user.deposits[i];
                if (deposit.time < now) {
                    _reward = _reward.add(deposit.amount);
                }
            }
        }
    }

    /// @dev Returns claimed and unclaimed user's reward.
    /// @param _user Address of the user.
    /// @return _reward User's reward.
    function getReward(address _user)
        public
        view
        virtual
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = user.reward.add(getPendingReward(_user, false));
    }

    /// @dev Returns approximate reward assessed in the future.
    /// @param _delta Time to estimate.
    /// @return Predicted rewardsV2.
    function getEstimated(uint256 _delta) public view returns (uint256) {
        return
            (now + _delta)
                .sub(lastUpdate)
                .mul(totalStake)
                .mul(rewardPerSec)
                .div(1e18);
    }

    /// @dev Returns user's deposit by id.
    /// @param _user Address of user.
    /// @param _id Deposit id.
    /// @return Deposited amount and deposit end time.
    function getDeposit(address _user, uint256 _id)
        public
        view
        returns (uint256, uint256)
    {
        DepositInfo memory deposit = userInfo[_user].deposits[_id];
        return (deposit.amount, deposit.time);
    }

    /// @dev Returns user's ended deposits.
    /// @param _user Address of the user.
    /// @return _count Number of the deposit's that can be withdrawn.
    function getEndedDepositsCount(address _user)
        public
        view
        virtual
        returns (uint256 _count)
    {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            if (deposit.time < now) {
                _count = _count.add(1);
            }
        }
    }
}
