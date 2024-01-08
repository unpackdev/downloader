//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IIntegrationManager {
    function addAuthUserForFund(address, address) external;

    function removeAuthUserForFund(address, address) external;

    function isAuthUserForFund(address, address) external view returns (bool);
}
