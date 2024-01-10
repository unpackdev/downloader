// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IComptroller {
    function claimComp(address holder) external;

    function getCompAddress() external view returns (address);
}
