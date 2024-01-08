// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IController {
    function isRelayer(address) external view returns (bool);

    function isTrustedPair(address) external view returns (bool);

    // function factory() external view returns (address);

    function router() external view returns (address);
}
