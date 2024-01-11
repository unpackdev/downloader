// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IModuleBase {
    function moduleIdentifier() external view returns (bytes32);

    function dealManager() external view returns (address);

    function hasDealExpired(uint32 _dealId) external view returns (bool);
}
