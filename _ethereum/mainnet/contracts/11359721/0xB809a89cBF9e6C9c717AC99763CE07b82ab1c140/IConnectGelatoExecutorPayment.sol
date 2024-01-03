// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./IInstaDapp.sol";

interface IConnectGelatoExecutorPayment is ConnectorInterface {
    function payExecutor(
        address _token,
        uint256 _amt,
        uint256 _getId,
        uint256 _setId
    ) external payable;
}
