// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IBPD {
    function callIncomeTokensTrigger(uint256 incomeAmountToken) external;
    function transferYearlyPool(uint256 poolNumber) external returns (uint256);
	function getPoolYearAmounts() external view returns (uint256[5] memory poolAmounts);
}
