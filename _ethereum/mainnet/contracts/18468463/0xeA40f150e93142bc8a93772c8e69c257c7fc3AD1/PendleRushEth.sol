// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ILocker.sol";
import "./IConvertor.sol";
import "./ISmartPendleConvert.sol";
import "./IPendleMarketDepositHelper.sol";
import "./IPendleRouter.sol";

/// @title PendleRushEth
/// @notice Contract for calculating incentive deposits and rewards points with the Pendle token
contract PendleRushEth is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    struct UserInfo {
        uint256 converted;
        uint256 rewardClaimed;
    }    

    IERC20 public PENDLE; // Pendle token
    address public mPENDLE; // Pendle tokenv
    IERC20 public PNP;    // Penpie token
    ILocker public vlPNP; 
    address public mPendleConvertor;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public tierLength;
    uint256 public totalAccumulated;
    
    uint256[] public rewardMultiplier;
    uint256[] public rewardTier;

    mapping(address => UserInfo) public userInfos; // Total conversion amount per user

    IPendleRouter public pendleRouter;

    uint256 public constant CONVERT_TO_MPENDLE = 1;
    uint256 public constant CONVERT_AND_STAKE = 2;
    uint256 public mPENDLEBonusRatio;

    /* ============ Events ============ */

    event VLPNPRewarded(address indexed _beneficiary, uint256 _vlPNPAmount);
    event BonusRatioChanged(uint256 _old, uint256 _new);

    /* ============ Errors ============ */

    error InvalidAmount();
    error LengthMissmatch();
    error InvalidMode();

    /* ============ Constructor ============ */
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialization ============ */

    function _PendleRushETH_init(
        address _pendle,
        address _vlPNP,
        address _PNP
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        PENDLE = IERC20(_pendle);
        vlPNP = ILocker(_vlPNP); 
        PNP = IERC20(_PNP);
        mPENDLEBonusRatio = 500;
    }

    /* ============ External Read Functions ============ */

    function quoteConvert(
        uint256 _amountToConvert,
        address _account
    ) external view returns (uint256) {
        UserInfo memory userInfo = userInfos[_account];
        uint256 pnpReward = 0;

        uint256 accumulatedRewards = _amountToConvert + userInfo.converted;
        uint256 i = 1;

        while (i < rewardTier.length && accumulatedRewards > rewardTier[i]) {
            pnpReward +=
                (rewardTier[i] - rewardTier[i - 1]) *
                rewardMultiplier[i - 1];
            i++;
        }

        pnpReward +=
            (accumulatedRewards - rewardTier[i - 1]) *
            rewardMultiplier[i - 1];

        pnpReward = (pnpReward / DENOMINATOR)- userInfo.rewardClaimed;
        uint256 pnpleft = PNP.balanceOf(address(this));

        uint256 finalReward = pnpReward > pnpleft ? pnpleft : pnpReward;
        return finalReward;

    }

    function getUserTier(address _account) public view returns (uint256) {
        uint256 userconverted = userInfos[_account].converted;
        for (uint256 i = tierLength - 1; i >= 1; i--) {
            if (userconverted >= rewardTier[i]) {
                return i;
            }
        }
        return 0;
    }

    function amountToNextTier(
        address _account
    ) external view returns (uint256) {
        uint256 userTier = this.getUserTier(_account);
        if (userTier == tierLength - 1) return 0;

        return rewardTier[userTier + 1] - userInfos[_account].converted;
    }

    /* ============ External Write Functions ============ */

    function convert(uint256 _amount, uint256 _convertMode) external whenNotPaused nonReentrant {
        if (_convertMode != CONVERT_TO_MPENDLE && _convertMode != CONVERT_AND_STAKE)
            revert InvalidMode();

        uint256 rewardToSend = this.quoteConvert(_amount, msg.sender);

        PENDLE.safeTransferFrom(msg.sender, address(this), _amount);
        PENDLE.safeApprove(mPendleConvertor, _amount);
        IConvertor(mPendleConvertor).convert(msg.sender, _amount, _convertMode);

        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.converted += _amount;
        userInfo.rewardClaimed += rewardToSend;
        totalAccumulated += _amount;

        // Lock the rewarded vlPNP
        PNP.safeApprove(address(vlPNP), rewardToSend);
        vlPNP.lockFor(rewardToSend, msg.sender);

        // extra fixed yield to convertor
        uint256 extra = _amount * mPENDLEBonusRatio / DENOMINATOR;
        IERC20(mPENDLE).safeTransfer(msg.sender, extra);
        
        emit VLPNPRewarded(msg.sender, rewardToSend);
    }

    /* ============ Admin Functions ============ */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMPendleConvertor(address _mPENDLE, address _mPendleConvertor) external onlyOwner {
        mPENDLE = _mPENDLE;
        mPendleConvertor = _mPendleConvertor;
    }

    function setMultiplier(
        uint256[] calldata _multiplier,
        uint256[] calldata _tier
    ) external onlyOwner {
        if (
            _multiplier.length == 0 ||
            _tier.length == 0 ||
            (_multiplier.length != _tier.length)
        ) revert LengthMissmatch();

        for (uint8 i ; i < _multiplier.length; ++i) {
            if (_multiplier[i] == 0) revert InvalidAmount();
            rewardMultiplier.push(_multiplier[i]);
            rewardTier.push(_tier[i]);
            tierLength += 1;
        }
    }

    function resetMultiplier() external onlyOwner {
        uint256 len = rewardMultiplier.length;
        for (uint8 i = 0; i < len; ++i) {
            rewardMultiplier.pop();
            rewardTier.pop();
        }

        tierLength = 0;
    }

    function adminWithdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }

    function setMPendleBonusRatio (uint256 _newRatio) external onlyOwner() {
        uint256 old = mPENDLEBonusRatio;
        mPENDLEBonusRatio = _newRatio;

        emit BonusRatioChanged(old, mPENDLEBonusRatio);
    }
}