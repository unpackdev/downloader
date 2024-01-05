// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1;

interface ICampaignFactory {
    function getPlatformFeeRate() external view returns (uint256);
    function getplatformRevenueAddress() external view returns (address);
}
