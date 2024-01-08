// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.8.4 <0.9.0;

interface ITreasury {
    function registerClaim(bytes32 _termsCid, address _fromAccount, address _toAccount, address _token, uint _amount) external returns(bool);
    function requestWithdraw(bytes32 _termsCid, address _toAccount, address _token, uint _amount) external returns(bool);
}