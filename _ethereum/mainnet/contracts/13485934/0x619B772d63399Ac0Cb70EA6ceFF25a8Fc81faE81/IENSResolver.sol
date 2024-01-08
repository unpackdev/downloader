//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IENSResolver {
    function addr(bytes32 node) external view returns (address);
}
