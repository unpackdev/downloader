// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

interface Versionable {
    function getContractVersion() external pure returns (string memory);
}