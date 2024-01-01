// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPausable {
    function paused() external view returns (bool);

    function everythingStopped() external view returns (bool);
}
