// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IDRFLord.sol";
import "./ISDRF.sol";

contract SDRFFarm is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event Claimed(uint256 amount);

    address public sdrf;
    address public drf;
    address public drfLord;
    address public nami;
    address public sdvd;

    bool public isFarmOpen = false;
    uint256 public farmOpenTime;

    uint256 public constant rewardAllocation = 300000e18;
    uint256 public rewardRate;
    uint256 public constant rewardDuration = 20 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public finishTime;

    uint256 public constant RATIO_MULTIPLIER = 100;

    struct AccountInfo {
        uint256 balance;
        uint256 reward;
        uint256 rewardPerTokenPaid;
        uint256 namiBalance;
        uint256 sdvdBalance;
    }

    /// @notice Account info
    mapping(address => AccountInfo) public accountInfos;

    /// @dev Total supply of staked tokens
    uint256 private _totalSupply;

    constructor(address _sdrf, address _drf, address _drfLord, address _nami, address _sdvd, uint256 _farmOpenTime) public {
        sdrf = _sdrf;
        drf = _drf;
        drfLord = _drfLord;
        nami = _nami;
        sdvd = _sdvd;
        farmOpenTime = _farmOpenTime;

        // Initialize
        lastUpdateTime = farmOpenTime;
        finishTime = farmOpenTime.add(rewardDuration);
        rewardRate = rewardAllocation.div(rewardDuration);
    }

    /* ========== Modifiers ========== */

    modifier farmOpen {
        require(isFarmOpen, 'Farm not open');
        _;
    }

    modifier checkOpenFarm() {
        require(farmOpenTime <= block.timestamp, 'Farm not open');
        if (!isFarmOpen) {
            // Set flag
            isFarmOpen = true;
        }
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].reward = earned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    /* ========== Mutative ========== */

    /// @notice Stake NAMI + DRF.
    function stakeNAMI(uint256 namiAmount) external nonReentrant checkOpenFarm updateReward(msg.sender) {
        require(namiAmount > 0, 'Cannot stake 0');

        // Transfer nami from sender
        IERC20(nami).transferFrom(msg.sender, address(this), namiAmount);

        // Get needed DRF
        uint256 drfAmount = namiAmount.mul(RATIO_MULTIPLIER);
        // Transfer DRF from sender
        // We use DRF lord to make it no fee and no reflect
        IDRFLord(drfLord).depositFromSDRFFarm(msg.sender, drfAmount);

        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(drfAmount);
        accountInfos[msg.sender].namiBalance = accountInfos[msg.sender].namiBalance.add(namiAmount);
        // Increase total supply
        _totalSupply = _totalSupply.add(drfAmount);

        emit Staked(msg.sender, namiAmount);
    }

    /// @notice Stake SDVD + DRF.
    function stakeSDVD(uint256 sdvdAmount) external nonReentrant checkOpenFarm updateReward(msg.sender) {
        require(sdvdAmount > 0, 'Cannot stake 0');

        // Note: SDVD has on fee transfer, so we need to calculate using balance
        uint256 sdvdBalanceBefore = IERC20(sdvd).balanceOf(address(this));
        // Transfer sdvd from sender
        IERC20(sdvd).transferFrom(msg.sender, address(this), sdvdAmount);
        // Get real sdvd received
        sdvdAmount = IERC20(sdvd).balanceOf(address(this)).sub(sdvdBalanceBefore);

        // Get needed DRF
        uint256 drfAmount = sdvdAmount.mul(RATIO_MULTIPLIER);

        // Transfer DRF from sender
        // We use DRF lord to make it no fee and no reflect
        IDRFLord(drfLord).depositFromSDRFFarm(msg.sender, drfAmount);

        // Add to balance
        // Use SDVD amount
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(drfAmount);
        accountInfos[msg.sender].sdvdBalance = accountInfos[msg.sender].sdvdBalance.add(sdvdAmount);
        // Increase total supply
        _totalSupply = _totalSupply.add(drfAmount);

        emit Staked(msg.sender, sdvdAmount);
    }

    /// @notice Withdraw NAMI + DRF.
    function withdrawNAMI(uint256 namiAmount) external nonReentrant farmOpen updateReward(msg.sender) {
        require(namiAmount > 0, 'Cannot withdraw 0');
        require(namiAmount <= accountInfos[msg.sender].namiBalance, 'Insufficient balance');

        // Get needed DRF
        uint256 drfAmount = namiAmount.mul(RATIO_MULTIPLIER);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(drfAmount);
        accountInfos[msg.sender].namiBalance = accountInfos[msg.sender].namiBalance.sub(namiAmount);
        // Reduce total supply
        _totalSupply = _totalSupply.sub(drfAmount);

        // Transfer to sender
        IDRFLord(drfLord).redeemFromSDRFFarm(msg.sender, drfAmount);
        IERC20(nami).transfer(msg.sender, namiAmount);

        emit Withdrawn(msg.sender, namiAmount);
    }

    /// @notice Withdraw SDVD + DRF.
    function withdrawSDVD(uint256 sdvdAmount) external nonReentrant farmOpen updateReward(msg.sender) {
        require(sdvdAmount > 0, 'Cannot withdraw 0');
        require(sdvdAmount <= accountInfos[msg.sender].sdvdBalance, 'Insufficient balance');

        // Get needed DRF
        uint256 drfAmount = sdvdAmount.mul(RATIO_MULTIPLIER);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(drfAmount);
        accountInfos[msg.sender].sdvdBalance = accountInfos[msg.sender].sdvdBalance.sub(sdvdAmount);
        // Reduce total supply
        _totalSupply = _totalSupply.sub(drfAmount);

        // Transfer to sender
        IDRFLord(drfLord).redeemFromSDRFFarm(msg.sender, drfAmount);
        IERC20(sdvd).transfer(msg.sender, sdvdAmount);

        emit Withdrawn(msg.sender, sdvdAmount);
    }

    /// @notice Claim reward.
    function claimReward() external nonReentrant farmOpen updateReward(msg.sender) returns (uint256 reward) {
        reward = accountInfos[msg.sender].reward;
        require(reward > 0, 'No reward');

        // Reduce reward first
        accountInfos[msg.sender].reward = 0;

        // Mint reward
        ISDRF(sdrf).mint(msg.sender, reward);

        emit Claimed(reward);
    }

    /* ========== View ========== */

    /// @notice Get staked token total supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get staked token balance
    function balanceOf(address account) public view returns (uint256) {
        return accountInfos[account].balance;
    }

    /// @notice Get staked nami balance
    function namiBalanceOf(address account) public view returns (uint256) {
        return accountInfos[account].namiBalance;
    }

    /// @notice Get staked sdvd balance
    function sdvdBalanceOf(address account) public view returns (uint256) {
        return accountInfos[account].sdvdBalance;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, finishTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

}
