/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IMint {
    function mint(uint256 value) external returns (bool);

    function mintTo(address to, uint256 value) external returns (bool);
}
