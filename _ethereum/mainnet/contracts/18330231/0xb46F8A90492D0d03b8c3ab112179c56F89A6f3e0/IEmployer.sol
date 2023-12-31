// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEmployer {
    function DEVELOPER_ADDRESS() external returns (address);
    function TIME_TOKEN_ADDRESS() external returns (address);
    function D() external returns (uint256);
    function FACTOR() external returns (uint256);
    function FIRST_BLOCK() external returns (uint256);
    function ONE_YEAR() external returns (uint256);
    function availableNative() external returns (uint256);
    function currentDepositedNative() external returns (uint256);
    function totalAnticipatedTime() external returns (uint256);
    function totalBurnedTime() external returns (uint256);
    function totalDepositedNative() external returns (uint256);
    function totalDepositedTime() external returns (uint256);
    function totalEarnedNative() external returns (uint256);
    function totalTimeSaved() external returns (uint256);
    function anticipationEnabled(address account) external returns (bool);
    function deposited(address account) external returns (uint256);
    function earned(address account) external view returns (uint256);
    function lastBlock(address account) external returns (uint256);
    function remainingTime(address account) external returns (uint256);
    function anticipate(uint256 timeAmount) external payable;
    function anticipationFee() external view returns (uint256);
    function compound(uint256 timeAmount, bool mustAnticipateTime) external;
    function deposit(uint256 timeAmount, bool mustAnticipateTime) external payable;
    function earn() external;
    function enableAnticipation() external payable;
    function getCurrentROI() external view returns (uint256);
    function getCurrentROIPerBlock() external view returns (uint256);
    function getROI() external view returns (uint256);
    function getROIPerBlock() external view returns (uint256);
    function queryAnticipatedEarnings(address depositant, uint256 anticipatedTime) external view returns (uint256);
    function queryEarnings(address depositant) external view returns (uint256);
    function withdrawEarnings() external;
    function withdrawDeposit() external;
    function withdrawDepositEmergency() external;
    receive() external payable;
}
