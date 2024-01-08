// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVesting {
    event Harvest(address indexed sender, uint256 amount);
    event Deposite(address indexed sender, uint256 amount, bool isFiat);
    event Deposites(address[] senders, uint256[] amounts);
    event SetSpecificAllocation(address[] users, uint256[] allocation);
    event IncreaseTotalSupply(uint256 amount);
    event SetTimePoint(uint256 startDate, uint256 endDate);

    enum VestingType {
        SWAP,
        LINEAR_VESTING,
        INTERVAL_VESTING
    }

    struct Interval {
        uint256 timeStamp;
        uint256 percentage;
    }

    struct VestingInfo {
        uint256 periodDuration;
        uint256 countPeriodOfVesting;
        uint256 cliffDuration;
        Interval[] unlockIntervals;
    }

    function initialize(
        string memory name_,
        address rewardToken_,
        address depositToken_,
        address signer_,
        uint256 initialUnlockPercentage_,
        uint256 minAllocation_,
        uint256 maxAllocation_,
        VestingType vestingType_
    ) external;

    function getAvailAmountToDeposit(address _addr)
        external
        view
        returns (uint256 minAvailAllocation, uint256 maxAvailAllocation);

    function getInfo()
        external
        view
        returns (
            string memory name,
            address stakedToken,
            address rewardToken,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 totalSupply,
            uint256 totalDeposited,
            uint256 tokenPrice,
            uint256 initialUnlockPercentage,
            VestingType vestingType
        );

    function getVestingInfo()
        external
        view
        returns (
            uint256 periodDuration,
            uint256 countPeriodOfVesting,
            Interval[] memory intervals
        );

    function getBalanceInfo(address _addr)
        external
        view
        returns (uint256 lockedBalance, uint256 unlockedBalance);

    function initializeToken(uint256 tokenPrice_, uint256 totalSypply_)
        external;

    function increaseTotalSupply(uint256 _amount) external;

    function setTimePoint(uint256 _startDate, uint256 _endDate) external;

    function setSigner(address addr_) external;

    function setSpecificAllocation(
        address[] calldata addrs_,
        uint256[] calldata amount_
    ) external;

    function setSpecificVesting(
        address addr_,
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        uint256 cliffPeriod_,
        Interval[] calldata intervals_
    ) external;

    function setVesting(
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        uint256 cliffPeriod_,
        Interval[] calldata intervals_
    ) external;

    function addDepositeAmount(
        address[] calldata _addrArr,
        uint256[] calldata _amountArr
    ) external;

    function completeVesting() external;

    function deposite(
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function harvestFor(address _addr) external;

    function harvest() external;

    function harvestInterval(uint256 intervalIndex) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function convertToToken(uint256 _amount) external view returns (uint256);

    function convertToCurrency(uint256 _amount) external view returns (uint256);

    function getTimePoint()
        external
        view
        returns (uint256 startDate, uint256 endDate);
}
