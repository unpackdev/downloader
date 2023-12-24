// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

interface IPortal {
    struct Obligation {
        address recipient;
        address asset;
        uint256 amount;
    }
    function writeObligations(Obligation[] calldata obligations) external;
    function rejectDeposits(bytes32[] calldata _depositHashes) external;
    function getAvailableBalance(address trader, address token) external view returns (uint256);
}
