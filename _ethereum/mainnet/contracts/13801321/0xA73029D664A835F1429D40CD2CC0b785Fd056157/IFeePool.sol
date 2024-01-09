// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IFeePool {
    function sendProfitERC20(address _account, uint256 _amount) external;
}
