// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITSCPool {
    function checkTokenOption(address _token) external view returns (bool);

    function getFee() external view returns (uint256);

    function calculateFee(address _sender) external returns (uint256);
}
