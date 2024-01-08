// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "./Math.sol";
import "./SafeCast.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./draft-IERC20Permit.sol";
import "./draft-ERC20Permit.sol";
import "./IEmission.sol";
import "./ILiquidityMining.sol";

error InvalidArguments();
error InvalidOrder();
error ForbiddenZeroArgument();
error ReferrerMismatch();
error ReferrerUnqualified();
error LockTimeExpired();
error InsufficientLockTime();
error TierQualificationFailed();
error UnstakeOrderCannotBeFilled();

contract LiquidityMining is ILiquidityMining, Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeCast for uint;
 
    /// a library for handling binary fixed point numbers https://en.wikipedia.org/wiki/Q_(number_format)
    uint private constant Q64 = 2**64;
    uint16 private constant REFERRAL_LINK_REWARD_IN_BP = 100; // 1% * BP
    uint16 private constant REFERRER_REWARD_IN_BP = 500; // 5% * BP
    uint16 private constant BP = 10_000;

    uint64 public constant override MIN_VESTING_TIME_IN_SECONDS = 7 days;
    address public override PHTR;
    address public override LP;
    address public override emission;
    uint16 public override minTierReferrerBooster;

    uint public override totalBoostedStake;
    mapping(address => mapping(uint8 => uint)) public _vestingOptionStake;
    
    uint private accumulatedPHTRInTotalSharesInQ;
    uint private exitFeesInPHTR;
    uint private lastPHTRBalance;

    Tier[] private tiers;
    uint[] private vestingLockDateInSeconds;
    uint16[] private vestingTimeBoostersInBP;
    mapping(address => AccountDetails) private accountOf;
    
    function initialize(
        address _PHTR, 
        address _LP, 
        address _emission,
        uint8 _minTierReferrerBoosterIndex,
        Tier[] memory _tiers, 
        uint[] memory _vestingLockDateInSeconds, 
        uint16[] memory _vestingTimeBoostersInBP
    ) initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();

        if (_PHTR == address(0) || _LP == address(0)) {
            revert ForbiddenZeroArgument();
        }
        if (
            _tiers.length < 2 // zero tier + 1 other tier
            || _tiers[0].boosterInBP != 0
            || _minTierReferrerBoosterIndex == 0
            || _tiers.length > type(uint8).max
            || _vestingLockDateInSeconds.length == 0
            || _vestingLockDateInSeconds.length > type(uint8).max
            || _vestingLockDateInSeconds.length != _vestingTimeBoostersInBP.length
        ) {
            revert InvalidArguments();
        }
        PHTR = _PHTR;
        LP = _LP;
        emission = _emission;
        minTierReferrerBooster = _tiers[_minTierReferrerBoosterIndex].boosterInBP;

        for (uint i; i < _tiers.length; ++i) {
            if (i > 0) {
                if (_tiers[i - 1].boosterInBP > _tiers[i].boosterInBP || _tiers[i - 1].thresholdInBP > _tiers[i].thresholdInBP) {
                    revert InvalidOrder();
                }
                if (_tiers[i].boosterInBP == 0) {
                    revert InvalidArguments();
                }
            }
            tiers.push(_tiers[i]);
        }

        for (uint i; i < _vestingLockDateInSeconds.length; ++i) {
            if (i > 0 && (
                _vestingLockDateInSeconds[i - 1] > _vestingLockDateInSeconds[i]
                || _vestingTimeBoostersInBP[i - 1] > _vestingTimeBoostersInBP[i]
            )) {
                revert InvalidOrder();
            }
            vestingLockDateInSeconds.push(_vestingLockDateInSeconds[i]);
            vestingTimeBoostersInBP.push(_vestingTimeBoostersInBP[i]);
        }
    } 

    function setEmission(address _emission) external onlyOwner {
        emission = _emission;
        emit SetEmission(msg.sender, _emission);
    }

    function stakeWithPermit(StakeWithPermitParams calldata _params) 
        external 
        override  
        nonReentrant 
        accumulateRewards(_params.referrer)
    {
        IERC20Permit(LP).permit(
            msg.sender, 
            address(this), 
            _params.approveMax ? type(uint).max : _params.amount, 
            _params.deadline, 
            _params.v, 
            _params.r, 
            _params.s
        );    
        _stake(_params.referrer, _params.amount, _params.minTierIndex, _params.vestingRange);
    }

    function stake(
        address _referrer, 
        uint _amount, 
        uint8 _minTierIndex, 
        VestingRange calldata _vestingRange
    )  
        external 
        override 
        nonReentrant 
        accumulateRewards(_referrer)
    {
        _stake(_referrer, _amount, _minTierIndex, _vestingRange);
    }
    
    function _stake(
        address _referrer, 
        uint _amount, 
        uint8 _minTierIndex, 
        VestingRange memory _vestingRange
    ) private {
        if (_vestingRange.startIndex > _vestingRange.endIndex) {
            revert InvalidArguments();
        }
        if (_amount == 0) {
            revert ForbiddenZeroArgument();
        }
        AccountDetails storage account = accountOf[msg.sender];

        if ((account.referrer != address(0) && account.referrer != _referrer) || _referrer == msg.sender) {
            revert ReferrerMismatch();
        }
        if (block.timestamp > vestingLockDateInSeconds[_vestingRange.startIndex] || block.timestamp > vestingLockDateInSeconds[_vestingRange.endIndex]) {
            revert LockTimeExpired();
        }
        if (vestingLockDateInSeconds[_vestingRange.startIndex] - block.timestamp < MIN_VESTING_TIME_IN_SECONDS) {
            revert InsufficientLockTime();
        }

        IERC20(LP).safeTransferFrom(msg.sender, address(this), _amount);
           
        // vesting booster = max achieved vesting option
        uint16 lastTierBoosterInBP = account.tierBoosterInBP;
        uint16 tierBoosterInBP_ = _tierBoosterInBP(account.totalStake + _amount, _minTierIndex);
        uint16 vestingBoosterInBP = vestingTimeBoostersInBP[_vestingRange.endIndex - _vestingRange.startIndex];
    
        _vestingOptionStake[msg.sender][_vestingRangeKey(_vestingRange)] += _amount;
        // tier booster is not reduceable during (re)staking
        account.tierBoosterInBP = uint16(Math.max(tierBoosterInBP_, lastTierBoosterInBP));
        account.vestedBoostedStake += (_amount * (BP + vestingBoosterInBP) / BP).toUint128();
        account.totalStake += _amount.toUint128();

        if (_referrer != address(0) && account.referrer == address(0)) {
            if (accountOf[_referrer].tierBoosterInBP < minTierReferrerBooster) {
                revert ReferrerUnqualified();
            }
            account.referrer = _referrer;
        }

        emit Stake(msg.sender, _amount, _vestingRange.startIndex, _vestingRange.endIndex);
    }

    function unstake(
        VestingRange[] calldata _vestingRanges, 
        uint _amount
    ) 
        external 
        override 
        nonReentrant 
        accumulateRewards(accountOf[msg.sender].referrer)
    {
        if (_amount == 0) {
            revert ForbiddenZeroArgument();
        }
        if (_vestingRanges.length == 0) {
            revert InvalidArguments();
        }
        
        AccountDetails storage account = accountOf[msg.sender];
        uint vestedBoostedStake;
        uint earlyUnstakedAmount;
        uint unstakedAmount;
        for (uint i; i < _vestingRanges.length; ++i) {
            VestingRange calldata vestingRange = _vestingRanges[i];
            if (vestingRange.startIndex > vestingRange.endIndex) {
                revert InvalidArguments();
            }
            uint vestingOptionStake_ = _vestingOptionStake[msg.sender][_vestingRangeKey(vestingRange)];
            uint16 vestingBoosterInBP = vestingTimeBoostersInBP[vestingRange.endIndex - vestingRange.startIndex];
            uint unstaked = unstakedAmount + vestingOptionStake_ > _amount ? _amount - unstakedAmount : vestingOptionStake_;
            if (unstaked == 0) {
                break;
            }
            if (block.timestamp < vestingLockDateInSeconds[vestingRange.endIndex]) {
                // early unstake
                earlyUnstakedAmount += unstaked;
            }
            unstakedAmount += unstaked;
            _vestingOptionStake[msg.sender][_vestingRangeKey(vestingRange)] -= unstaked;            
            vestedBoostedStake += unstaked * (BP + vestingBoosterInBP) / BP;

            emit UnstakeRange(msg.sender, unstaked, vestingRange.startIndex, vestingRange.endIndex);
        }
        if (unstakedAmount != _amount) {
            revert UnstakeOrderCannotBeFilled();
        }

        IERC20(LP).safeTransfer(msg.sender, _amount);
        
        uint totalAmountInPHTR = _amount * account.rewardInPHTR / account.totalStake;
        uint exitFeeInPHTR = earlyUnstakedAmount * account.rewardInPHTR / account.totalStake;
        if (exitFeeInPHTR > 0) {
           exitFeesInPHTR += exitFeeInPHTR;
        }
        uint rewardInPHTR = totalAmountInPHTR - exitFeeInPHTR;
        if (rewardInPHTR > 0) {
            IERC20(PHTR).safeTransfer(msg.sender, rewardInPHTR);
        }
        
        account.vestedBoostedStake -= vestedBoostedStake.toUint128();
        account.tierBoosterInBP = _tierBoosterInBP(account.totalStake - _amount, 0);
        account.totalStake -= _amount.toUint128();
        account.rewardInPHTR -= totalAmountInPHTR;

        emit Unstake(msg.sender, _amount, totalAmountInPHTR, exitFeeInPHTR);
    }

    function programDetails() 
        external 
        view 
        override
        returns (
            uint _totalBoostedStake,
            uint _accumulatedPHTRInTotalSharesInQ,
            Tier[] memory _tiers,
            uint[] memory _vestingDatesInSeconds, 
            uint[] memory _vestingTimeBoostersInBP
        ) 
    {
        _totalBoostedStake = totalBoostedStake;
        _accumulatedPHTRInTotalSharesInQ = accumulatedPHTRInTotalSharesInQ;
        _tiers = tiers;
        _vestingDatesInSeconds = new uint[](vestingLockDateInSeconds.length);
        _vestingTimeBoostersInBP = new uint[](vestingTimeBoostersInBP.length);
        
        for (uint i; i < vestingLockDateInSeconds.length; ++i) {
            _vestingDatesInSeconds[i] = vestingLockDateInSeconds[i];
            _vestingTimeBoostersInBP[i] = vestingTimeBoostersInBP[i];
        }
    }

    function accountDetails(address _account) 
        external 
        view 
        override
        returns (
            uint _boostedStake,
            uint _totalReward,
            AccountDetails memory _accountDetails
        ) 
    {
        _boostedStake = _boostedStakeOf(_account);
        _accountDetails = accountOf[_account];
        uint PHTRIncrease = exitFeesInPHTR + IEmission(emission).withdrawable() + IERC20(PHTR).balanceOf(address(this)) - lastPHTRBalance;
        uint _accumulatedPHTRInTotalSharesInQ = accumulatedPHTRInTotalSharesInQ;
        if (PHTRIncrease > 0 && totalBoostedStake > 0) {
            unchecked { // overflow is desired
                _accumulatedPHTRInTotalSharesInQ += PHTRIncrease * Q64 / totalBoostedStake;    
            }  
        }
        uint last = accountOf[_account].totalStake == 0 ? _accumulatedPHTRInTotalSharesInQ : accountOf[_account].lastAccumulatedPHTRInTotalBoostedStakeInQ;
        uint accumulatedPHTRInTotalSharesIncreaseInQ;
        unchecked { // overflow is desired
            accumulatedPHTRInTotalSharesIncreaseInQ = _accumulatedPHTRInTotalSharesInQ - last;
        }
        uint rewardInPHTR = _boostedStake * accumulatedPHTRInTotalSharesIncreaseInQ / Q64;
        _totalReward = rewardInPHTR + _accountDetails.rewardInPHTR;
    }

    function tierBoosterInBP(uint _amount, uint8 _minTierIndex) external view override returns (uint16) {
        return _tierBoosterInBP(_amount, _minTierIndex);
    }

    function vestingOptionStake(
        address _account, 
        VestingRange calldata _vestingRange
    ) 
        external 
        view 
        override 
        returns (uint) 
    {
        return _vestingOptionStake[_account][_vestingRangeKey(_vestingRange)];
    }

    function _updateReferralBooster(address _referrer, uint _newReferralBoosterInBP, uint _lastReferralBoosterInBP) private {
        // let lastStake == 0 without referrer
        // lastStake == 0 && stake != 0 = mint referral booster
        // lastStake != 0 && stake == 0 = burn referral booster
        // lastStake != 0 && stake != 0 = update referral booster
        // lastStake == 0 && stake == 0 = referral booster stays zero
        if (_referrer == address(0) || accountOf[msg.sender].tierBoosterInBP < minTierReferrerBooster) {
            return;
        }
        
        if (_lastReferralBoosterInBP == type(uint).max) {
            uint newReferralBoosterInBP = accountOf[_referrer].referralBoosterInBP + _newReferralBoosterInBP;
            accountOf[_referrer].referralBoosterInBP += uint16(Math.min(type(uint16).max, newReferralBoosterInBP));
        } else {
            // TODO: handle subtraction lower bound
            if (accountOf[_referrer].referralBoosterInBP + _newReferralBoosterInBP < _lastReferralBoosterInBP) {
                accountOf[_referrer].referralBoosterInBP = 0;
            } else {
                uint newReferralBoosterInBP = accountOf[_referrer].referralBoosterInBP + _newReferralBoosterInBP - _lastReferralBoosterInBP;
                accountOf[_referrer].referralBoosterInBP = uint16(Math.min(type(uint16).max, newReferralBoosterInBP));
            }
        }
    }

    function _updateAccountReward(address _account, uint _boostedStake) private {
        if (_account == address(0)) {
            return;
        }
        
        // TODO: check if this works together with referrer
        uint last = accountOf[_account].totalStake == 0 ? accumulatedPHTRInTotalSharesInQ : accountOf[_account].lastAccumulatedPHTRInTotalBoostedStakeInQ;
        uint accumulatedPHTRInTotalSharesIncreaseInQ;
        unchecked { // overflow is desired
            accumulatedPHTRInTotalSharesIncreaseInQ = accumulatedPHTRInTotalSharesInQ - last;
        }
        uint rewardInPHTR = _boostedStake * accumulatedPHTRInTotalSharesIncreaseInQ / Q64;
        if (rewardInPHTR > 0) {
            accountOf[_account].rewardInPHTR += rewardInPHTR;
        }
        
        accountOf[_account].lastAccumulatedPHTRInTotalBoostedStakeInQ = accumulatedPHTRInTotalSharesInQ;
    }

    function _referralBoosterInBP(address _account, uint _boostedStake) private view returns (uint) {
        if (accountOf[_account].referrer == address(0)) {
            return type(uint).max; // 'unset' booster state
        }
        uint stake_ = accountOf[_account].totalStake;
        if (stake_ == 0) {
            return 0;
        }
        uint referralBoosterInBP = accountOf[_account].referralBoosterInBP;
        uint allBoosters = _boostedStake * BP / stake_ - BP;
        uint allBoostersWithoutReferral = allBoosters < referralBoosterInBP ? 0 : allBoosters - referralBoosterInBP;
        return REFERRER_REWARD_IN_BP * allBoostersWithoutReferral / BP;
    }
    
    function _boostedStakeOf(address _account) private view returns (uint) {
        if (_account == address(0)) {
            return 0;
        }
        AccountDetails storage account = accountOf[_account];
        uint16 referralLinkBoosterInBP = account.referrer == address(0) ? 0 : REFERRAL_LINK_REWARD_IN_BP; 
        uint vestedBoosterInBP;
        if (account.totalStake > 0) {
           vestedBoosterInBP = (account.vestedBoostedStake * BP / account.totalStake) - BP;
        }
        return (BP + account.tierBoosterInBP + account.referralBoosterInBP + referralLinkBoosterInBP + vestedBoosterInBP) * account.totalStake / BP;
    }

    function _tierBoosterInBP(uint _amount, uint8 _minTierIndex) private view returns (uint16 tierBoosterInBP_) {
        // LP.totalSupply cannot be zero on UNI-V2 (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol#L121)
        uint accountTotalStakeInBP = _amount * BP / IERC20(LP).totalSupply();
        for (uint i = tiers.length; i > 0; --i) {
            // tier booster = totalStake as a percentage of total LP
            if (accountTotalStakeInBP >= tiers[i - 1].thresholdInBP) {
                if (_minTierIndex > i - 1) {
                    revert TierQualificationFailed();
                }
                tierBoosterInBP_ = tiers[i - 1].boosterInBP;
                break;
            } 
        }  
    }

    /// @dev Encodes _vestingRange with unique key combination
    function _vestingRangeKey(VestingRange memory _vestingRange) private view returns (uint8) {
        return (_vestingRange.startIndex * vestingLockDateInSeconds.length + _vestingRange.endIndex).toUint8();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @dev Accumulates unclaimed PHTR reward for account and it's referrer
    modifier accumulateRewards(address _referrer) {
        uint lastBoostedStake = _boostedStakeOf(msg.sender);
        uint lastBoostedStakeOfReferrer = _boostedStakeOf(_referrer);
        uint lastReferralBoosterInBP = _referralBoosterInBP(msg.sender, lastBoostedStake);

        if (totalBoostedStake > 0) {
            IEmission(emission).withdraw();
            uint PHTRIncrease = IERC20(PHTR).balanceOf(address(this)) - lastPHTRBalance + exitFeesInPHTR;
            if (PHTRIncrease > 0) {
                unchecked { // overflow is desired
                    accumulatedPHTRInTotalSharesInQ += PHTRIncrease * Q64 / totalBoostedStake;    
                }   
                exitFeesInPHTR = 0; // unset exit fee carry
            }
            _updateAccountReward(msg.sender, lastBoostedStake);
            _updateAccountReward(_referrer, lastBoostedStakeOfReferrer);
        }

        _;
        
        uint boostedStake = _boostedStakeOf(msg.sender);
        _updateReferralBooster(_referrer, _referralBoosterInBP(msg.sender, boostedStake), lastReferralBoosterInBP);
        // lastBoostedStakeOfReferrer must be accounted somewhere for last value to be subtracted even if referrer is not present
        uint lastBoostedStakeWithReferrer = lastBoostedStake + lastBoostedStakeOfReferrer;
        uint boostedStakeWithReferrer = boostedStake + _boostedStakeOf(_referrer);
        if (boostedStakeWithReferrer > lastBoostedStakeWithReferrer) {
            totalBoostedStake += boostedStakeWithReferrer - lastBoostedStakeWithReferrer;
        } else if (lastBoostedStakeWithReferrer > boostedStakeWithReferrer) {
            totalBoostedStake -= lastBoostedStakeWithReferrer - boostedStakeWithReferrer;
        }
        if (totalBoostedStake + lastBoostedStakeWithReferrer > 0) { // don't account for last PHTR when previous total stake was zero
            // TODO: log state here
            lastPHTRBalance = IERC20(PHTR).balanceOf(address(this));
        }
    }
}