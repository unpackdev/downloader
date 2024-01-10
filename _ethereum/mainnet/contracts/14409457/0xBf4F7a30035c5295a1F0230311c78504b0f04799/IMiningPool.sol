pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC165.sol";
import "./IERC20.sol";
import "./IUniswapV3Pool.sol";
import "./IERC223Recipient.sol";
import "./IERC677Recipient.sol";
import "./IERC1363Receiver.sol";
import "./IOwnable.sol";

interface IMiningPool is IOwnable, IERC165, IERC223Recipient, IERC677Recipient, IERC1363Receiver {
    function initialize(
        IERC20 _tokenToStake,
        IERC20 _tokenToReward,
        IUniswapV3Pool _referenceUniswapV3Pool,
        uint256 _totalAnnualRewards,
        uint256 _fixedPoolCapacityUSD,
        uint64 _lockPeriod,
        uint64 _rewardPeriod,
        uint64 _redeemWaitPeriod,
        bool _isTokenToStakeWETH
    ) external;

    function getTokenToStake() external view returns (address);

    function getTokenToReward() external view returns (address);

    function getReferenceUniswapV3Pool() external view returns (address);

    function getTotalAnnualRewards() external view returns (uint256);

    function getFixedPoolCapacityUSD() external view returns (uint256);

    function getFixedPoolUsageUSD() external view returns (uint256);

    function getLockPeriod() external view returns (uint64);

    function getRewardPeriod() external view returns (uint64);

    function getRedeemWaitPeriod() external view returns (uint64);

    function getPoolStake() external view returns (uint256);

    function getPoolStakeAt(uint64 timestamp) external view returns (Record memory);

    function getPoolRequestedToRedeem() external view returns (uint256);

    function getUserStake(address userAddr) external view returns (uint256);

    function getUserStakeAt(address userAddr, uint64 timestamp) external view returns (Record memory);

    function getUserStakeLocked(address userAddr) external view returns (uint256);

    function getUserStakeUnlocked(address userAddr) external view returns (uint256);

    function getUserStakeDetails(address userAddr) external view returns (StakeRecord[] memory);

    function getUserStakeRewards(address userAddr) external view returns (uint256);

    function getUserStakeRewardsDetails(address userAddr) external view returns (Record[] memory);

    function getUserRewardsAt(
        address userAddr,
        uint64 timestamp,
        int256 price,
        uint8 decimals
    ) external view returns (Record memory);

    function getUserRequestedToRedeem(address userAddr) external view returns (uint256);

    function getUserCanRedeemNow(address userAddr) external view returns (uint256);

    function getUserRedemptionDetails(address userAddr) external view returns (Record[] memory);

    function stakeToken(uint256 amount) external;

    function stakeETH() external payable;

    function claimStakeRewards() external;

    function requestRedemption(uint256 amount) external;

    function redeemToken() external;

    function redeemETH() external;

    function getAllUsers() external view returns (address[] memory);

    function setPriceConsultSeconds(uint32 _priceConsultSeconds) external;

    function getWithdrawers() external view returns (address[] memory);

    function grantWithdrawer(address withdrawerAddr) external;

    function revokeWithdrawer(address withdrawerAddr) external;

    function poolDeposit(uint256 amount) external;

    function poolDepositETH() external payable;

    function poolWithdraw(uint256 amount) external;

    function poolWithdrawETH(uint256 amount) external;

    event StakeRewards(address indexed userAddr, uint256 stakeAmount, uint256 stakeRewardsAmount, uint64 stakeTime, uint64 nodeID, bytes32 stakeHash);

    event FixedPoolStaking(address indexed userAddr, uint256 tokenAmount, uint256 equivUSD);

    event StakeToken(address indexed userAddr, uint256 amount);

    event ClaimStakeRewards(address indexed userAddr, uint256 amount);

    event RequestRedemption(address indexed userAddr, uint256 amount);

    event RedeemToken(address indexed userAddr, uint256 amount);

    struct Record {
        uint256 amount;
        uint64 timestamp;
    }

    struct StakeRecord {
        uint256 currentStakeAmount;
        uint256 initialStakeAmount;
        uint256 stakeRewardsAmount;
        uint64 timestamp;
    }
}
