// SPDX-License-Identifier: MIT

import "./SafeERC20.sol";
import "./AccessControl.sol";

pragma solidity ^0.8.20;

interface IVault {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claimRewards() external;
    function artiUtilizeForMaxYield(uint256 amount) external;
    function artiReturnAssets(uint256 amount) external;
    function artiDistributeDAIRewards() external;
    function artiDistributeAifiRewards() external;
}

contract DAIVault is IVault, AccessControl {
    using SafeERC20 for IERC20;
    bytes32 public constant ARTI_OPERATOR = keccak256("ARTI_OPERATOR");

    event Deposit(address user, uint256 amount, uint256 depositTime);
    event Withdraw(address user, uint256 amount);
    event RewardsClaimed(
        address user,
        uint256 daiRewards,
        uint256 aifiRewards
    );
    event ArtiFundsUtilized(uint256 amount);
    event ArtiAssetsReturned(uint256 amount);
    event DAIDistributed(uint256 amount, uint256 duration);
    event AifiDistributed(uint256 amount, uint256 duration);

    struct UserDeposit {
        uint256 amount;
        uint256 lastClaimedTime;
    }

    struct claimedRewards {
        uint256 DAIRewardsClaimed;
        uint256 aifiRewardsClaimed;
    }
    mapping(address => UserDeposit) private userDeposits;
    mapping(address => claimedRewards) private rewardsClaimed;

    uint256 public maxStableDeposits = 20000 * 10 ** 18;
    uint256 public DAI_APY_PERCENT;
    uint256 public AIFI_APY_PERCENT;
    uint256 public constant APY_BASE = 100; // Base percentage for calculations

    uint256 public totalStablesDeposited;
    uint256 public DAIUtilized;
    uint256 public totalDAIDistributed;
    uint256 public totalAifiDistributed;
    uint256 public daiLastRewardTime;
    uint256 public aifiLastRewardTime;

    IERC20 public DAI;
    IERC20 public AIFI;

    constructor(IERC20 _dai, IERC20 _aifi, address _arti) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARTI_OPERATOR, _arti);
        DAI = _dai;
        AIFI = _aifi;
        daiLastRewardTime = block.timestamp;
        aifiLastRewardTime = block.timestamp;
        AIFI_APY_PERCENT = 3;
        DAI_APY_PERCENT = 7;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "zero deposits");
        require(
            totalStablesDeposited + amount <= maxStableDeposits,
            "max 20K only"
        );
        UserDeposit storage deposits = userDeposits[msg.sender];

        DAI.safeTransferFrom(msg.sender, address(this), amount);
        deposits.amount += amount;
        totalStablesDeposited += amount;
        if (deposits.lastClaimedTime == 0) {
            deposits.lastClaimedTime = block.timestamp;
        }
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    function withdraw(uint256 amount) external {
        require(msg.sender != address(0), "zero address");
        UserDeposit storage deposits = userDeposits[msg.sender];
        require(deposits.amount >= amount, "Insufficient deposit");

        deposits.amount -= amount;
        claimRewards();

        DAI.safeTransfer(msg.sender, amount);
        totalStablesDeposited -= amount;
        if (deposits.amount == 0) {
            deposits.lastClaimedTime = 0;
        }
        emit Withdraw(msg.sender, amount);
    }

    function claimRewards() public {
        if (totalAifiDistributed == 0 && totalDAIDistributed == 0) {
            return;
        }
        uint256 daiRewards = calculateDAIRewards(msg.sender);
        uint256 aifiRewards = calculateAifiRewards(msg.sender);

        uint256 daiBalance = DAI.balanceOf(address(this));
        if (daiRewards > 0 && daiBalance >= daiRewards) {
            DAI.safeTransfer(msg.sender, daiRewards);
        }

        uint256 aifiBalance = AIFI.balanceOf(address(this));
        if (aifiRewards > 0 && aifiBalance >= aifiRewards) {
            AIFI.safeTransfer(msg.sender, aifiRewards);
        }
        userDeposits[msg.sender].lastClaimedTime = block.timestamp;
        claimedRewards storage userClaims = rewardsClaimed[msg.sender];
        userClaims.DAIRewardsClaimed += daiBalance;
        userClaims.aifiRewardsClaimed += aifiBalance;

        emit RewardsClaimed(msg.sender, daiBalance, aifiRewards);
    }

    function calculateAifiRewards(address user) public view returns (uint256) {
        UserDeposit memory deposits = userDeposits[user];
        if (deposits.lastClaimedTime == 0 && deposits.amount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - deposits.lastClaimedTime;
        uint256 yearlyReward = (deposits.amount * AIFI_APY_PERCENT) / APY_BASE;
        return (yearlyReward * timeElapsed) / 365 days;
    }

    function calculateDAIRewards(address user) public view returns (uint256) {
        UserDeposit memory deposits = userDeposits[user];
        if (deposits.lastClaimedTime == 0 && deposits.amount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - deposits.lastClaimedTime;
        uint256 yearlyReward = (deposits.amount * DAI_APY_PERCENT) / APY_BASE;
        return (yearlyReward * timeElapsed) / 365 days;
    }

    function artiUtilizeForMaxYield(
        uint256 amount
    ) external onlyRole(ARTI_OPERATOR) {
        require(amount > 0, "zero amount");
        uint256 maxFundsUtilizationAllowed = totalStablesDeposited / 2;
        require(
            DAIUtilized + amount <= maxFundsUtilizationAllowed,
            "max 50% utlization allowed"
        );

        DAI.safeTransfer(msg.sender, amount);
        DAIUtilized += amount;
        emit ArtiFundsUtilized(amount);
    }

    function artiReturnAssets(uint amount) external onlyRole(ARTI_OPERATOR) {
        require(amount > 0, "zero amount");

        DAI.safeTransferFrom(msg.sender, address(this), amount);
        DAIUtilized -= amount;

        emit ArtiAssetsReturned(amount);
    }

    function artiDistributeDAIRewards() external onlyRole(ARTI_OPERATOR) {
        require(
            block.timestamp > daiLastRewardTime,
            "Too soon to distribute rewards"
        );

        uint256 timeElapsed = block.timestamp - daiLastRewardTime;
        uint256 yearlyRewards = (totalStablesDeposited * DAI_APY_PERCENT) /
            APY_BASE;

        uint256 rewardsAmount = (yearlyRewards / 365 days) * timeElapsed;

        DAI.safeTransferFrom(msg.sender, address(this), rewardsAmount);
        totalDAIDistributed += rewardsAmount;
        daiLastRewardTime = block.timestamp;

        emit DAIDistributed(rewardsAmount, timeElapsed);
    }

    function artiDistributeAifiRewards() external onlyRole(ARTI_OPERATOR) {
        require(
            block.timestamp > aifiLastRewardTime,
            "Too soon to distribute rewards"
        );

        uint256 timeElapsed = block.timestamp - aifiLastRewardTime;
        uint256 yearlyRewards = (totalStablesDeposited * AIFI_APY_PERCENT) /
            APY_BASE;

        uint256 rewardsAmount = (yearlyRewards / 365 days) * timeElapsed;

        AIFI.safeTransferFrom(msg.sender, address(this), rewardsAmount);
        totalAifiDistributed += rewardsAmount;
        aifiLastRewardTime = block.timestamp;

        emit AifiDistributed(rewardsAmount, timeElapsed);
    }

    function getUserDeposits(
        address user
    ) external view returns (UserDeposit memory) {
        return userDeposits[user];
    }

    function userRewardsClaimed(
        address user
    ) external view returns (claimedRewards memory) {
        return rewardsClaimed[user];
    }

     function setDAIYieldRew(uint256 _bps) external onlyRole(ARTI_OPERATOR) {
        require(_bps > 4, "min 5 allowed");
        DAI_APY_PERCENT = _bps;
    } 

    function setAIFIYieldRew(uint256 _bps) external onlyRole(ARTI_OPERATOR) {
        require(_bps > 2, "min 3 allowed");
        AIFI_APY_PERCENT = _bps;
    }

    function updateAddrs(IERC20 _dai, IERC20 _aifi) external onlyRole(ARTI_OPERATOR) {
        DAI = _dai;
        AIFI = _aifi;
    }

    function protectTokens() external onlyRole(ARTI_OPERATOR) {
        uint256 dai = DAI.balanceOf(address(this));
        DAI.safeTransfer(msg.sender, dai);

        uint256 aifi = AIFI.balanceOf(address(this));
        DAI.safeTransfer(msg.sender, aifi);
    }
}