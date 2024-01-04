// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IMcdManager {
    function ilks(uint256) external view returns (bytes32);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);

    function owns(uint256) external view returns (address);
}
