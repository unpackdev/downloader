// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";

/**
 * @notice Compound V2's cEther interface
 */
interface ICEther is IERC20 {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint256);
    function underlying() external view returns (address);
    function repayBorrowBehalf(address borrower) external payable returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function borrowBalanceStored(address account) external view returns (uint256);
}
