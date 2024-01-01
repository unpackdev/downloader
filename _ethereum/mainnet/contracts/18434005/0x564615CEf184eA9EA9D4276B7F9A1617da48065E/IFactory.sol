//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFactory {
    function isSignerOrAdmin(address wallet) external view returns (bool, bool);

    function baseURI() external view returns (string memory);
}
