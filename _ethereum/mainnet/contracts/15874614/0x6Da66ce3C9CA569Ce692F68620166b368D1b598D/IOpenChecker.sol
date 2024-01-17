// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenChecker {
    function checkErcInterfaces(address smartcontract)
        external
        view
        returns (bool[] memory interfaceIdsChecks);

    function checkSupportedInterfaces(address smartcontract, bool erc, bytes4[] memory interfaceIds)
        external
        view
        returns (bool[] memory interfaceIdsChecks);

    function isCollection(address collection) external view returns (bool check);

    function isCollections(address[] memory collection)
        external
        view
        returns (bool[] memory checks);
}
