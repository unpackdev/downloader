// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/// @title Fund - the fund interface
/// @notice This contract extends ERC20, defines basic fund functions and rewrites ERC20 transferFrom function
interface IFund {


    /// @notice Convert fund amount to cash amount
    /// @dev This converts the user fund amount to cash amount when a user redeems the fund
    /// @param fundAmount Redeem fund amount
    /// @return Cash amount
    function convertToCash(uint256 fundAmount) external view returns (uint256);

    /// @notice Fund token address for joining and redeeming
    /// @dev This is address is created when the fund is first created.
    /// @return Fund token address
    function ioToken() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);


}
