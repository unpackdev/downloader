// SPDX-License-Identifier: UNLICSENSED
pragma solidity ^0.8.18;

interface IFeeDistributor {
    struct Fee {
        address payable payee;
        bytes32 token;
        uint256 amount;
    }

    function distributeFee(Fee calldata fee) external payable;

    function distributeFees(Fee[] calldata fees) external payable;
}
