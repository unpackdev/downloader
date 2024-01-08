pragma solidity ^0.6.0;

interface IReferralProgram {
    struct User {
        bool exists;
        address referrer;
    }

    function users(address wallet)
        external
        returns (bool exists, address referrer);

    function registerUser(address referrer, address referral) external;

    function feeReceiving(
        address _for,
        address _token,
        uint256 _amount
    ) external;
}
