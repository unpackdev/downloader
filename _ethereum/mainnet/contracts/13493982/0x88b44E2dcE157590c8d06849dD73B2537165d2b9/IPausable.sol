// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IPausable {

    event Paused(address account);

    event Unpaused(address account);

    function paused() external view returns (bool);
}
