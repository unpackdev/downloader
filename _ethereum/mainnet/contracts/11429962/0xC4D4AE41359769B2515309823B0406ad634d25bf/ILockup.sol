// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ILockup {
    function withdraw(address _property, uint256 _amount) external;
    function getValue(address _property, address _sender) external view returns (uint256);
    function calculateWithdrawableInterestAmount(address _property, address _user) external view returns (uint256);
}
