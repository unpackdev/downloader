// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectDebtBridgeFee {
    function calculateFee(
        uint256 _amount,
        uint256 _ftf,
        uint256 _fee,
        uint256 _getId,
        uint256 _setId,
        uint256 _setIdFee
    ) external payable;
}
