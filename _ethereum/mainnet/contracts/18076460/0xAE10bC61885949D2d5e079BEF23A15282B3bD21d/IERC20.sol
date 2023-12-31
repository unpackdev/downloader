// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {

    /**
        @notice Transfer token for a specified address.
        @param _to The address to transfer to.
        @param _value The amount to be transferred.
        @return true if the transfer is successful, false otherwise.
    */
    function transfer(address _to, uint256 _value) external returns (bool);

    /**
        @notice Transfer tokens from one address to another.
        @param _from The address which you want to send tokens from.
        @param _to The address to transfer to.
        @param _value The amount to be transferred.
        @return true if the transfer is successful, false otherwise.
    */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

}
