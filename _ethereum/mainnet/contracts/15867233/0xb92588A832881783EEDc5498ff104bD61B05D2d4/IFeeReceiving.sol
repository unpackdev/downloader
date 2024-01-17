// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFeeReceiving {
    function feeReceiving(
        address _sender,
        address _token,
        uint256 _amount
    ) external;
}
