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
    function artiDistributeUSDCRewards() external;
    function artiDistributeAifiRewards() external;
}

contract USDCVault is IVault, AccessControl {
    using SafeERC20 for IERC20;
    bytes32 public constant ARTI_OPERATOR = keccak256("ARTI_OPERATOR");

    event Deposit(address user, uint256 amount, uint256 depositTime);
    event Withdraw(address user, uint256 amount);
    event RewardsClaimed(
        address user,
        uint256 usdcRewards,
        uint256 aifiRewards
    );
    event ArtiFundsUtilized(uint256 amount);
    event ArtiAssetsReturned(uint256 amount);
    event USDCDistributed(uint256 amount, uint256 duration);
    event AifiDistributed(uint256 amount, uint256 duration);

    struct UserDeposit {
        uint256 amount;
        uint256 lastClaimedTime;
    }

    struct claimedRewards {
        uint256 USDCRewardsClaimed;
        uint256 aifiRewardsClaimed;
    }
    mapping(address => UserDeposit) private userDeposits;
    mapping(address => claimedRewards) private rewardsClaimed;

    uint256 public maxStableDeposits = 20000 * 10 ** 6;
    uint256 public constant USDC_APY_PERCENT = 7; // APY percentage (7%)
    uint256 public constant AIFI_APY_PERCENT = 3; // APY percentage (3%)
    uint256 public constant APY_BASE = 100; // Base percentage for calculations

    uint256 public totalStablesDeposited;
    uint256 public fundsUtilized;
    uint256 public totalUSDCDistributed;
    uint256 public totalAifiDistributed;
    uint256 public usdcLastRewardTime;
    uint256 public aifiLastRewardTime;

    IERC20 public USDC;
    IERC20 public aifi;

    constructor(IERC20 _usdc, IERC20 _aifi, address _arti) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARTI_OPERATOR, _arti);
        USDC = _usdc;
        aifi = _aifi;
        usdcLastRewardTime = block.timestamp;
        aifiLastRewardTime = block.timestamp;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "zero deposits");
        require(
            totalStablesDeposited + amount <= maxStableDeposits,
            "max 20K only"
        );
        UserDeposit storage deposits = userDeposits[msg.sender];

        USDC.safeTransferFrom(msg.sender, address(this), amount);
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
        deposits.lastClaimedTime = 0;

        USDC.safeTransfer(msg.sender, amount);
        totalStablesDeposited -= amount;
        if (deposits.amount == 0) {
            deposits.lastClaimedTime = 0;
        }
        emit Withdraw(msg.sender, amount);
    }

    function claimRewards() public {
        if (totalAifiDistributed == 0 && totalUSDCDistributed == 0) {
            return;
        }
        uint256 usdcRewards = calculateUSDCRewards(msg.sender);
        uint256 aifiRewards = calculateAifiRewards(msg.sender);

        uint256 usdcBalance = USDC.balanceOf(address(this));
        if (usdcRewards > 0 && usdcBalance >= usdcRewards) {
            USDC.safeTransfer(msg.sender, usdcRewards);
        }

        uint256 aifiBalance = aifi.balanceOf(address(this));
        if (aifiRewards > 0 && aifiBalance >= aifiRewards) {
            aifi.safeTransfer(msg.sender, aifiRewards);
        }
        userDeposits[msg.sender].lastClaimedTime = block.timestamp;
        claimedRewards storage userClaims = rewardsClaimed[msg.sender];
        userClaims.USDCRewardsClaimed += usdcBalance;
        userClaims.aifiRewardsClaimed += aifiBalance;

        emit RewardsClaimed(msg.sender, usdcRewards, aifiRewards);
    }

    function calculateAifiRewards(address user) public view returns (uint256) {
        UserDeposit memory deposits = userDeposits[user];
        if (deposits.lastClaimedTime == 0 || deposits.amount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - deposits.lastClaimedTime;
        uint256 yearlyReward = (deposits.amount * AIFI_APY_PERCENT) / APY_BASE;
        return (yearlyReward * timeElapsed) / 365 days;
    }

    function calculateUSDCRewards(address user) public view returns (uint256) {
        UserDeposit memory deposits = userDeposits[user];
        if (deposits.lastClaimedTime == 0 || deposits.amount == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - deposits.lastClaimedTime;
        uint256 yearlyReward = (deposits.amount * USDC_APY_PERCENT) / APY_BASE;
        return (yearlyReward * timeElapsed) / 365 days;
    }

    function artiUtilizeForMaxYield(
        uint256 amount
    ) external onlyRole(ARTI_OPERATOR) {
        require(amount > 0, "zero amount");
        uint256 maxFundsUtilizationAllowed = totalStablesDeposited / 2;
        require(
            fundsUtilized + amount <= maxFundsUtilizationAllowed,
            "max 50% utlization allowed"
        );

        USDC.safeTransfer(msg.sender, amount);
        fundsUtilized += amount;
        emit ArtiFundsUtilized(amount);
    }

    function artiReturnAssets(uint amount) external onlyRole(ARTI_OPERATOR) {
        require(amount > 0, "zero amount");

        USDC.safeTransferFrom(msg.sender, address(this), amount);
        fundsUtilized -= amount;

        emit ArtiAssetsReturned(amount);
    }

    function artiDistributeUSDCRewards() external onlyRole(ARTI_OPERATOR) {
        require(
            block.timestamp > usdcLastRewardTime,
            "Too soon to distribute rewards"
        );

        uint256 timeElapsed = block.timestamp - usdcLastRewardTime;
        uint256 yearlyRewards = (totalStablesDeposited * USDC_APY_PERCENT) /
            APY_BASE;

        uint256 rewardsAmount = (yearlyRewards / 365 days) * timeElapsed;

        USDC.safeTransferFrom(msg.sender, address(this), rewardsAmount);
        totalUSDCDistributed += rewardsAmount;
        usdcLastRewardTime = block.timestamp;

        emit USDCDistributed(rewardsAmount, timeElapsed);
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

        aifi.safeTransferFrom(msg.sender, address(this), rewardsAmount);
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
}