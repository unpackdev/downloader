// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IENSHelpers {
    function getEnsDomain(address _address) external view returns (string memory);
}