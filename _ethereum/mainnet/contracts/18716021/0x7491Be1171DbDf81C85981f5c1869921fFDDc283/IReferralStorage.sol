// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.21;

interface IReferralStorage {
    function codeOwner(bytes32 _code) external view returns (address);
    function accountCodeOwned(address _account) external view returns (bytes32);
    function accountReferralCode(address _account) external view returns (bytes32);
    function setAccountReferralCode(address _account, bytes32 _code) external;
    function getAccountReferralInfo(address _account) external view returns (bytes32, address);
    function adminSetCodeOwner(bytes32 _code, address _newAccount) external;
}
