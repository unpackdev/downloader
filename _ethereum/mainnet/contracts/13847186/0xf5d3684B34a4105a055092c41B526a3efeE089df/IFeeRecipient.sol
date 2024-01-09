// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IFeeRecipient {
  function pushToken(address _token, uint _amount) external;
}
