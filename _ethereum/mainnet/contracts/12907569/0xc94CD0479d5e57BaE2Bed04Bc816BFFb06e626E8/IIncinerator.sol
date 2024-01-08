// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

interface IIncinerator {

    function incinerate(address tokenAddr) external payable;
}
