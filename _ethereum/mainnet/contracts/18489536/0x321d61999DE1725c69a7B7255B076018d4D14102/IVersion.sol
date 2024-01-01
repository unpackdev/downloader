// commit 72851dc7b28e8982506694bd739a08d668212610
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IVersion {
    function NAME() external view returns (bytes32 name);

    function VERSION() external view returns (uint256 version);
}
