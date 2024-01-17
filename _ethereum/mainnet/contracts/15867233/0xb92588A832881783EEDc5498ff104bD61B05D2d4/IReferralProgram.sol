// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IReferralProgram {
    struct User {
        bool exists;
        address referrer;
    }

    function users(address wallet)
        external
        returns (User memory user);

    function registerUser(address referrer, address referral) external;

    function rootAddress() external view returns(address);
    function rewards(address user, address token) external view returns(uint256);

    function feeReceiving(
        address _for,
        address _token,
        uint256 _amount
    ) external;
}
