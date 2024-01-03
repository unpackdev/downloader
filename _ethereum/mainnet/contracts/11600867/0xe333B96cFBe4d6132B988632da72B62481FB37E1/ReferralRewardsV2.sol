pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./IMintableBurnableERC20.sol";
import "./IReferralTree.sol";
import "./IRewardsV2.sol";
import "./IRewards.sol";

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
