//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IProxyCache {
    function read(bytes memory _code) external view returns (address);

    function write(bytes memory _code) external returns (address target);
}
