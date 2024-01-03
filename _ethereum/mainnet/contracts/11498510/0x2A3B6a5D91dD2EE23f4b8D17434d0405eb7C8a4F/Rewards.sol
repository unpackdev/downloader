pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReferralTree.sol";
import "./dANT.sol";
import "./ReferralRewards.sol";

abstract contract Rewards is Ownable {
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
        uint256 lastUpdate; // Last time the user claimed rewards
        uint256 depositHead; // The start index in the deposit's list
        uint256 depositTail; // The end index in the deposit's list
        mapping(uint256 => DepositInfo) deposits; // User's dposits
    }

    dANT public token; // Harvested token contract
    ReferralRewards public referralRewards; // Contract that manages referral rewards

    uint256 public duration; // How long the deposit works
    uint256 public rewardPerSec; // Reward rate generated each second
    uint256 public totalStake; // Amount of all staked LP tokens
    uint256 public totalClaimed; // Amount of all distributed rewards
    uint256 public lastUpdate; // Last time someone received rewards

    bool public isActive = true; // If the deposits are allowed

    mapping(address => UserInfo) public userInfo; // Info per each user

    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _duration How long the deposit works.
    /// @param _rewardPerSec Reward rate generated each second.
    constructor(
        dANT _token,
        uint256 _duration,
        uint256 _rewardPerSec
    ) public Ownable() {
        token = _token;
        duration = _duration;
        rewardPerSec = _rewardPerSec;
    }

    /// @dev Allows an owner to stop or countinue deposits.
    /// @param _isActive Whether the deposits are allowed.
    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    /// @dev Allows an owner to update referral rewards module.
    /// @param _referralRewards Contract that manages referral rewards.
    function setReferralRewards(ReferralRewards _referralRewards)
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
        proccessStake(_user, _amount, address(0));
    }

    /// @dev Allows to stake for themselves.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    function stake(uint256 _amount, address _refferal) public {
        proccessStake(msg.sender, _amount, _refferal);
    }

    /// @dev Proccess the stake.
    /// @param _receiver Deposit receiver.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    function proccessStake(
        address _receiver,
        uint256 _amount,
        address _refferal
    ) internal {
        require(isActive, "stake: is paused");
        referralRewards.setReferral(_receiver, _refferal);
        referralRewards.claimAllDividends(_receiver);
        updateStakingReward(_receiver);
        if (_amount > 0) {
            token.transferFrom(msg.sender, address(this), _amount);
            UserInfo storage user = userInfo[_receiver];
            user.amount = user.amount.add(_amount);
            totalStake = totalStake.add(_amount);
            user.deposits[user.depositTail] = DepositInfo({
                amount: _amount,
                time: now + duration
            });
            emit Deposit(
                _receiver,
                user.depositTail,
                _amount,
                now,
                now + duration
            );
            user.depositTail = user.depositTail.add(1);
            referralRewards.assessReferalDepositReward(_receiver, _amount);
        }
    }

    /// @dev Accumulate new reward and remove old deposits.
    /// @param _user Address of the user.
    /// @return _reward Earned reward.
    function accumulateStakingReward(address _user)
        internal
        virtual
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(user.lastUpdate)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
            );
            if (deposit.time < now) {
                referralRewards.claimAllDividends(_user);
                user.amount = user.amount.sub(deposit.amount);
                handleDepositEnd(_user, deposit.amount);
                delete user.deposits[i];
                user.depositHead = user.depositHead.add(1);
            }
        }
    }

    /// @dev Assess new reward.
    /// @param _user Address of the user.
    function updateStakingReward(address _user) internal virtual {
        UserInfo storage user = userInfo[_user];
        if (user.lastUpdate >= now) {
            return;
        }
        uint256 scaledReward = accumulateStakingReward(_user);
        uint256 reward = scaledReward.div(1e18);
        lastUpdate = now;
        user.reward = user.reward.add(reward);
        user.lastUpdate = now;
        if (reward > 0) {
            totalClaimed = totalClaimed.add(reward);
            token.mint(_user, reward);
            emit RewardPaid(_user, reward);
        }
    }

    /// @dev Procces deposit and by returning deposit.
    /// @param _user Address of the user.
    /// @param _amount Amount of the deposit.
    function handleDepositEnd(address _user, uint256 _amount) internal virtual {
        totalStake = totalStake.sub(_amount);
        safeTokenTransfer(_user, _amount);
        emit Withdraw(_user, 0, _amount, now);
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
        virtual
        view
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(user.lastUpdate)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
                    .div(1e18)
            );
            if (_includeDeposit && deposit.time < now) {
                _reward = _reward.add(deposit.amount);
            }
        }
    }

    /// @dev Returns claimed and unclaimed user's reward.
    /// @param _user Address of the user.
    /// @return _reward User's reward.
    function getReward(address _user)
        public
        virtual
        view
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = user.reward;
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(user.lastUpdate)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
                    .div(1e18)
            );
        }
    }

    /// @dev Returns referral stakes.
    /// @param _referrals List of referrals[].
    /// @return _stakes List of referral stakes.
    function getReferralStakes(address[] memory _referrals)
        public
        view
        returns (uint256[] memory _stakes)
    {
        _stakes = new uint256[](_referrals.length);
        for (uint256 i = 0; i < _referrals.length; i++) {
            _stakes[i] = userInfo[_referrals[i]].amount;
        }
    }

    /// @dev Returns referral stake.
    /// @param _referral Address of referral.
    /// @return Deposited amount.
    function getReferralStake(address _referral) public view returns (uint256) {
        return userInfo[_referral].amount;
    }

    /// @dev Returns approximate reward assessed in the future.
    /// @param _delta Time to estimate.
    /// @return Predicted rewards.
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
}
