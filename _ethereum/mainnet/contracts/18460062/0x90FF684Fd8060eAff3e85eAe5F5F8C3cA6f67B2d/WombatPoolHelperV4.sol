// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20.sol";

import "./IBaseRewardPool.sol";
import "./IHarvesttablePoolHelper.sol";
import "./IWombatStakingV2.sol";
import "./IMasterWombat.sol";
import "./IMasterMagpie.sol";
import "./IMintableERC20.sol";
import "./IWNative.sol";
import "./ISimpleHelper.sol";
/// @title WombatPoolHelper
/// @author Magpie Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Wombat Pool

/// @dev PoolHelperV4 is currently only on Ethereum Mainnet.
// Difference between V4 and V1 are:
// 1. The withdrawLP functionality to withdraw LP token from masterWombat
// 2. The functionality to claim rewards with withdraw of deposit tokens or LP tokens
// 3. The stakingToken(used to be the receipt token on masterMagpie) and its related logic are now removed.

contract WombatPoolHelperV4 {
    using SafeERC20 for IERC20;

    /* ============ Constants ============ */

    address public immutable depositToken; // token to deposit into wombat
    address public immutable lpToken; // lp token receive from wombat, also the pool identified on womabtStaking
    address public immutable mWom;

    address public immutable masterMagpieV2;
    address public immutable wombatStakingV2;
    address public immutable rewarderV4;

    uint256 public immutable pid; // pid on master wombat

    bool public immutable isNative;

    /* ============ Events ============ */

    event NewDeposit(address indexed _user, uint256 _amount);
    event NewLpDeposit(address indexed _user, uint256 _amount);
    event NewWithdraw(address indexed _user, uint256 _amount);
    event NewLpWithdraw(address indexed _user, uint256 _amount);

    /* ============ Errors ============ */

    error NotNativeToken();

    /* ============ Constructor ============ */

    constructor(
        uint256 _pid,
        address _depositToken,
        address _lpToken,
        address _wombatStaking,
        address _masterMagpie,
        address _rewarder,
        address _mWom,
        bool _isNative
    ) {
        pid = _pid;
        depositToken = _depositToken;
        lpToken = _lpToken;
        wombatStakingV2 = _wombatStaking;
        masterMagpieV2 = _masterMagpie;
        rewarderV4 = _rewarder;
        mWom = _mWom;
        isNative = _isNative;
    }

    /* ============ External Getters ============ */

    /// notice get the amount of total staked LP token in master magpie
    function totalStaked() external view returns (uint256) {
        return IBaseRewardPool(rewarderV4).totalStaked();
    }

    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(
        address _address
    ) external view returns (uint256) {
        return IBaseRewardPool(rewarderV4).balanceOf(_address);
    }

    /// @notice returns the number of pending MGP of the contract for the given pool
    /// returns pendingTokens the number of pending MGP
    function pendingWom() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterWombat(
            IWombatStaking(wombatStakingV2).masterWombat()
        ).pendingTokens(pid, wombatStakingV2);
    }

    /* ============ External Functions ============ */

    /// @notice deposit stables in wombat pool, autostake in master magpie
    /// @param _amount the amount of stables to deposit
    function deposit(
        uint256 _amount,
        uint256 _minimumLiquidity
    ) external {
        _deposit(_amount, _minimumLiquidity, msg.sender, msg.sender);
    }

    function depositFor(uint256 _amount, address _for) external {
        IERC20(depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(depositToken).safeApprove(wombatStakingV2, _amount);
        _deposit(_amount, 0, _for, address(this));
    }

    function depositLP(uint256 _lpAmount) external {
        IWombatStaking(wombatStakingV2).depositLP(lpToken, _lpAmount, msg.sender);
        _stake(_lpAmount, msg.sender);

        emit NewLpDeposit(msg.sender, _lpAmount);
    }

    function depositNative(uint256 _minimumLiquidity) external payable {
        if (!isNative) revert NotNativeToken();
        // Dose need to limit the amount must > 0?

        // Swap the BNB to wBNB
        _wrapNative();
        // depsoit wBNB to the pool
        IWNative(depositToken).approve(wombatStakingV2, msg.value);
        _deposit(msg.value, _minimumLiquidity, msg.sender, address(this));
        IWNative(depositToken).approve(wombatStakingV2, 0);
    }

    /// @notice withdraw stables from wombat pool, auto unstake from master Magpie
    /// @param _liquidity the amount of liquidity to withdraw
    function withdraw(
        uint256 _liquidity,
        uint256 _minAmount
    ) external {
        _withdraw(_liquidity, _minAmount, false);
    }

    function withdrawAndClaim(
        uint256 _liquidity,
        uint256 _minAmount,
        bool _isClaim
    ) external {
        _withdraw(_liquidity, _minAmount, _isClaim);
    }

    function withdrawLP(uint256 _amount, bool claim) external {
        // withdraw from wombat exchange and harvest rewards to base rewarder
        IWombatStaking(wombatStakingV2).withdrawLP(lpToken, _amount, msg.sender);
        // unstke from Master Wombat and trigger reward distribution from basereward
        _unstake(_amount, msg.sender);
        // claim all rewards
        if (claim) _claimRewards(msg.sender);
        emit NewLpWithdraw(msg.sender, _amount);
    }

    function harvest() external {
        IWombatStaking(wombatStakingV2).harvest(lpToken);
    }

    /* ============ Internal Functions ============ */

    function _withdraw(
        uint256 _liquidity,
        uint256 _minAmount,
        bool _claim
    ) internal {
        // we have to withdraw from wombat exchange to harvest reward to base rewarder
        IWombatStaking(wombatStakingV2).withdraw(
            lpToken,
            _liquidity,
            _minAmount,
            msg.sender
        );
        // then we unstake from master wombat to trigger reward distribution from basereward
        _unstake(_liquidity, msg.sender);

        if (_claim) _claimRewards(msg.sender);
        emit NewWithdraw(msg.sender, _liquidity);
    }

    function _claimRewards(address _for) internal {
        address[] memory stakingTokens = new address[](1);
        stakingTokens[0] = lpToken;
        address[][] memory rewardTokens = new address[][](1);
        IMasterMagpie(masterMagpieV2).multiclaimFor(
            stakingTokens,
            rewardTokens,
            _for
        );
    }

    function _deposit(
        uint256 _amount,
        uint256 _minimumLiquidity,
        address _for,
        address _from
    ) internal {
        uint256 lpReceived = IWombatStaking(wombatStakingV2).deposit(
            lpToken,
            _amount,
            _minimumLiquidity,
            _for,
            _from
        );
        _stake(lpReceived, _for);

        emit NewDeposit(_for, _amount);
    }

    function _wrapNative() internal {
        IWNative(depositToken).deposit{value: msg.value}();
    }

    /// @notice stake the receipt token in the masterchief of GMP on behalf of the caller
    function _stake(uint256 _amount, address _sender) internal {
        IMasterMagpie(masterMagpieV2).depositFor(lpToken, _amount, _sender);
    }

    /// @notice unstake from the masterchief of GMP on behalf of the caller
    function _unstake(uint256 _amount, address _sender) internal {
        IMasterMagpie(masterMagpieV2).withdrawFor(lpToken, _amount, _sender);
    }
}
