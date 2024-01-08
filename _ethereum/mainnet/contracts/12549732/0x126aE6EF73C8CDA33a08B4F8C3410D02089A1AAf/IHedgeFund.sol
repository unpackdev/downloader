// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IHedgeFund {
    function depositToHedgeFund(address token, uint256 amount) external returns (uint256 returnHaifAmount);
    function withdrawFromHedgeFund(uint256 amount) external returns (uint256 removedHaifAmount);
    function hedgePrice() external view returns (uint256);
}