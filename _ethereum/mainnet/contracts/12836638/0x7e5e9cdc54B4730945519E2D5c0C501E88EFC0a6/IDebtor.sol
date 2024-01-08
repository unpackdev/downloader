// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IDebtor {
    // Debtor should implement accounting at `withdrawAsCreditor()` and `askToInvestAsCreditor()`
    function withdrawAsCreditor(uint256 _amount) external returns (uint256);
    function askToInvestAsCreditor(uint256 _amount) external returns (uint256);

    function baseAssetBalanceOf(
        address _address
    ) external view returns (uint256);
}