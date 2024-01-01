// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @notice Aave WETH gateway interface
 */
interface IWethGateway {
    function withdrawETH(address lendingPool, uint256 amount, address to) external;
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;
    function repayETH(address lendingPool, uint256 amount, uint256 rateMode, address onBehalfOf) external payable;
    function borrowETH(address lendingPool, uint256 amount, uint256 interestRateMode, uint16 referralCode)
        external
        payable;
}
