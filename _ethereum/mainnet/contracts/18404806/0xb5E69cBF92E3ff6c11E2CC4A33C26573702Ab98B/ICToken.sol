// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IERC20.sol";

/**
 * @notice Compound V2's cToken interface
 */
interface ICToken is IERC20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint256);
    function underlying() external view returns (address);
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
}
