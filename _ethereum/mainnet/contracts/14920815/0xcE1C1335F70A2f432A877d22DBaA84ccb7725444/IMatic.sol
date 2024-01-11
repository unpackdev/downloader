// SPDX-FileCopyrightText: 2021 Tenderize <info@tenderize.me>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// note this contract interface is only for stakeManager use
interface IMatic {
    function exchangeRate() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function validatorId() external view returns (uint256);
}
