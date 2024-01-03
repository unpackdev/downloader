pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReferralTree.sol";
import "./dANT.sol";

contract ReferralRewards is Ownable {
    using SafeMath for uint256;

    event ReferralDepositReward(
        address indexed refferer,
        address indexed refferal,
        uint256 indexed level,
        uint256 amount
    );
    event ReferralRewardPaid(address indexed user, uint256 amount);

    // Info of each deposit made by the referrer
    struct DepositInfo {
        address referrer; // Address of refferer who made this deposit
        uint256 depth; // The level of the refferal
        uint256 amount; // Amount of deposited LP tokens
        uint256 time; // Wnen the deposit is ended
        uint256 lastUpdatedTime; // Last time the referral claimed reward from the deposit
    }
    // Info of each referral
    struct ReferralInfo {
        uint256 reward; // Ammount of collected deposit rewards
        uint256 lastUpdate; // Last time the referral claimed rewards
        uint256 depositHead; // The start index in the deposit's list
        uint256 depositTail; // The end index in the deposit's list
        uint256[amtLevels] amounts; // Amounts that generate rewards on each referral level
        mapping(uint256 => DepositInfo) deposits; // Deposits that generate reward for the referral
    }

    uint256 public constant amtLevels = 3; // Number of levels by total staked amount that determine referral reward's rate
    uint256 public constant referDepth = 3; // Number of referral levels that can receive dividends

    dANT public token; // Harvested token contract
    ReferralTree public referralTree; // Contract with referral's tree
    Rewards rewards; // Main farming contract

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
        dANT _token,
        ReferralTree _referralTree,
        Rewards _rewards,
        uint256[amtLevels] memory _depositBounds,
        uint256[referDepth][amtLevels] memory _depositRate,
        uint256[referDepth][amtLevels] memory _stakingRate
    ) public Ownable() {
        token = _token;
        referralTree = _referralTree;
        depositBounds = _depositBounds;
        depositRate = _depositRate;
        stakingRate = _stakingRate;
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

    /// @dev Allows a farming contract to set user referral.
    /// @param _referrer Address of the referred user.
    /// @param _referral Address of the refferal.
    function setReferral(address _referrer, address _referral) public {
        require(
            msg.sender == address(rewards),
            "assessReferalDepositReward: bad role"
        );
        referralTree.setReferral(_referrer, _referral);
    }

    /// @dev Allows the main farming contract to assess referral deposit rewards.
    /// @param _referrer Address of the referred user.
    /// @param _amount Amount of new deposit.
    function assessReferalDepositReward(address _referrer, uint256 _amount)
        external
        virtual
    {
        require(
            msg.sender == address(rewards),
            "assessReferalDepositReward: bad role"
        );
        address[] memory referrals = referralTree.getReferrals(
            _referrer,
            referDepth
        );
        uint256[] memory referralStakes = rewards.getReferralStakes(referrals);
        uint256[] memory percents = getDepositRate(referralStakes);
        for (uint256 level = 0; level < referrals.length; level++) {
            if (referrals[level] == address(0)) {
                continue;
            }


                ReferralInfo storage referralInfo
             = referralReward[referrals[level]];
            referralInfo.deposits[referralInfo.depositTail] = DepositInfo({
                referrer: _referrer,
                depth: level,
                amount: _amount,
                lastUpdatedTime: now,
                time: now + rewards.duration()
            });
            referralInfo.amounts[level] = referralInfo.amounts[level].add(
                _amount
            );
            referralInfo.depositTail = referralInfo.depositTail.add(1);
            if (percents[level] == 0) {
                continue;
            }
            uint256 depositReward = _amount.mul(percents[level]);
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

    /// @dev Allows a user to claim his dividends.
    function claimDividends() public {
        claimUserDividends(msg.sender);
    }

    /// @dev Allows a referral tree to claim all the dividends.
    /// @param _referral Address of user that claims his dividends.
    function claimAllDividends(address _referral) public {
        require(
            msg.sender == address(referralTree) ||
                msg.sender == address(rewards),
            "claimAllDividends: bad role"
        );
        claimUserDividends(_referral);
    }

    /// @dev Allows to decrement staked amount that generates reward to the referrals.
    /// @param _referrer Address of the referrer.
    /// @param _amount Ammount of tokens to be withdrawn by referrer.
    function removeDepositReward(address _referrer, uint256 _amount)
        external
        virtual
    {}

    /// @dev Update the staking referral reward for _user.
    /// @param _user Address of the referral.
    function accumulateReward(address _user) internal virtual {
        ReferralInfo storage referralInfo = referralReward[_user];
        if (referralInfo.lastUpdate >= now) {
            return;
        }
        uint256 rewardPerSec = rewards.rewardPerSec();
        uint256 referralStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates = getStakingRateRange(referralStake);
        for (
            uint256 i = referralInfo.depositHead;
            i < referralInfo.depositTail;
            i++
        ) {
            DepositInfo memory deposit = referralInfo.deposits[i];
            uint256 reward = Math
                .min(now, deposit.time)
                .sub(deposit.lastUpdatedTime)
                .mul(deposit.amount)
                .mul(rewardPerSec)
                .mul(rates[deposit.depth])
                .div(1e18);
            if (reward > 0) {
                referralInfo.reward = referralInfo.reward.add(reward);
            }
            referralInfo.deposits[i].lastUpdatedTime = now;
            if (deposit.time < now) {
                if (i != referralInfo.depositHead) {
                    referralInfo.deposits[i] = referralInfo
                        .deposits[referralInfo.depositHead];
                }
                delete referralInfo.deposits[referralInfo.depositHead];
                referralInfo.depositHead = referralInfo.depositHead.add(1);
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
    function getReferralReward(address _user)
        external
        virtual
        view
        returns (uint256)
    {
        ReferralInfo storage referralInfo = referralReward[_user];
        uint256 rewardPerSec = rewards.rewardPerSec();
        uint256 referralStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates = getStakingRateRange(referralStake);
        uint256 _reward = referralInfo.reward;
        for (
            uint256 i = referralInfo.depositHead;
            i < referralInfo.depositTail;
            i++
        ) {
            DepositInfo memory deposit = referralInfo.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(deposit.lastUpdatedTime)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
                    .mul(rates[deposit.depth])
                    .div(1e18)
            );
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
    /// @param _referralStakes Amounts staked by referrals.
    /// @return _rates Array of deposit rates by referral level.
    function getDepositRate(uint256[] memory _referralStakes)
        public
        view
        returns (uint256[] memory _rates)
    {
        _rates = new uint256[](_referralStakes.length);
        for (uint256 level = 0; level < _referralStakes.length; level++) {
            for (uint256 j = 0; j < depositBounds.length; j++) {
                if (_referralStakes[level] >= depositBounds[j]) {
                    _rates[level] = depositRate[j][level];
                    break;
                }
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
