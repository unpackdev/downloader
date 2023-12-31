// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";

struct StrategyInfo {
    // Info on each strategy
    IERC20 assetToken; // Address of asset token e.g. USDT
    IERC20 guaranteeToken; // Guarantee Token address e.g. Stone
    ICivFundRT fundRepresentToken; // Fund Represent tokens for deposit in the strategy XCIV
    uint fee; // Strategy Fee Amount
    uint guaranteeFee; // Strategy Guarantee Fee Amount
    uint maxDeposit; // Strategy Max Deposit Amount per Epoch
    uint maxUsers; // Strategy Max User per Epoch
    uint minDeposit; // Strategy Min Deposit Amount
    uint epochDuration; // Duration of an Epoch
    uint lockPeriod; // Strategy Guarantee Token Lock Period
    uint feeDuration; // Fee withdraw period
    uint lastFeeDistribution; // Last timestamp of distribution
    uint lastProcessedEpoch; // Last Epoch Processed
    uint watermark; // Fee watermark
    uint pendingFees; // Pending fees that owner can withdraw
    address[] withdrawAddress; // Strategy Withdraw Address
    address investAddress; // Strategy Invest Address
    bool initialized; // Is strategy initialized?
    bool paused; // Flag that deposit is paused or not
}

struct EpochInfo {
    uint totDepositors; // Current depositors of the epoch
    uint totDepositedAssets; // Tot deposited asset in current epoch
    uint totWithdrawnShares; // Tot withdrawn asset in current epoch
    uint VPS; // VPS after rebalancing
    uint newShares; // New shares after rebalancing
    uint currentWithdrawAssets; // Withdrawn asset after rebalancing
    uint epochStartTime; // Epoch start time from time oracle
    uint lastDepositorProcessed; // Last depositor that has recived shares
    uint duration;
}

struct UserInfo {
    uint lastEpoch; // Last withdraw epoch
    uint startingIndexGuarantee; // Starting index of guarantee lock
    uint numberOfLocks; // Number of guarantee locks the user has
}

struct GuaranteeInfo {
    uint lockStartTime; // startTime of the guarantee lock
    uint lockAmount; // Amount of guarantee locked
}

struct UserInfoEpoch {
    uint depositInfo;
    uint withdrawInfo;
    uint depositIndex;
    uint epochGuaranteeIndex;
    bool hasDeposited;
}

struct AddStrategyParam {
    IERC20 _assetToken;
    IERC20 _guaranteeToken;
    uint _maxDeposit;
    uint _maxUsers;
    uint _minAmount;
    uint _fee;
    uint _guaranteeFee;
    uint _epochDuration;
    uint _lockPeriod;
    uint _feeDuration;
    address _investAddress;
    address[] _withdrawAddresses;
    bool _paused;
}

struct PairInfo {
    IUniswapV2Pair pair; //Uniswap Pair Address
    uint price0CumulativeLast;
    uint price1CumulativeLast;
    FixedPoint.uq112x112 price0Average; // First token average price
    FixedPoint.uq112x112 price1Average; // Second token average price
    uint32 blockTimestampLast; //Last time we calculate price
    address token0; // First token address
    address token1; // Second token address
}

interface ICivVault {
    function guaranteeFee() external view returns (uint);

    function feeBase() external view returns (uint);

    function getStrategyInfo(
        uint _id
    ) external view returns (StrategyInfo memory);

    function getEpochInfo(
        uint _id,
        uint _index
    ) external view returns (EpochInfo memory);

    function getCurrentEpoch(uint _id) external view returns (uint);

    function getUserInfo(
        uint _id,
        address _user
    ) external view returns (UserInfo memory);

    function getUserInfoEpoch(
        uint _id,
        address _user,
        uint _index
    ) external view returns (UserInfoEpoch memory);

    function getGuaranteeInfo(
        uint _idid,
        address _user,
        uint _index
    ) external view returns (GuaranteeInfo memory);
}

interface ICivFundRT is IERC20 {
    function decimals() external view returns (uint8);

    function mint(uint _amount) external returns (bool);

    function burn(uint _amount) external returns (bool);
}

interface ICivVaultGetter {
    function addUniPair(uint, address, address) external;

    function getPrice(uint, uint) external view returns (uint);

    function getReversePrice(uint, uint) external view returns (uint);

    function getBalanceOfUser(uint, address) external view returns (uint);

    function updateAll(uint) external;

    function addTimeOracle(uint, uint) external;

    function setEpochDuration(uint, uint) external;

    function getCurrentPeriod(uint) external view returns (uint);
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint);

    function symbol() external view returns (string memory);
}
