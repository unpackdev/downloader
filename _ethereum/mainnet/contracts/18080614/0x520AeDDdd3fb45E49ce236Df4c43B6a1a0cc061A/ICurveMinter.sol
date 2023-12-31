// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveMinter {
    function mint(address gauge_addr) external;
}
