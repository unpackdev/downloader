// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRewardProvider {

    event Mint(address indexed sender, uint amountBlxm, uint amountToken);
    event Burn(address indexed sender, uint amountBlxm, uint amountToken, uint rewardAmount, address indexed to);
    event AddRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event ArrangeFailedRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event AllPosition(address indexed owner, address indexed token, uint liquidity, uint extraLiquidity, uint32 startHour, uint32 endLocking, uint indexed idx);
    event SyncStatistics(address indexed sender, address indexed token, uint liquidityIn, uint liquidityOut, uint aggregatedRewards, uint32 hour);

    function getRewardFactor(uint16 _days) external view returns (uint factor);
    function updateRewardFactor(uint16 lockedDays, uint factor) external returns (bool);

    function allPosition(address investor, uint idx) external view returns(address token, uint liquidity, uint extraLiquidity, uint32 startHour, uint32 endLocking);
    function allPositionLength(address investor) external view returns (uint);
    function calcRewards(address investor, uint idx) external returns (uint amount, bool isLocked);
    
    function getTreasuryFields(address token) external view returns (uint32 syncHour, uint totalLiquidity, uint pendingRewards, uint32 initialHour, uint16 lastSession);
    function getDailyStatistics(address token, uint32 hourFromEpoch) external view returns (uint liquidityIn, uint liquidityOut, uint aggregatedRewards, uint32 next);
    function syncStatistics(address token) external;
    function hoursToSession(address token, uint32 hourFromEpoch) external view returns (uint16 session);
    function getPeriods(address token, uint16 session) external view returns (uint amountPerHours, uint32 startHour, uint32 endHour);

    function decimals() external pure returns (uint8);
}