/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IBurn {
    function burn(uint256 value) external returns (bool);

    function burnFrom(address from, uint256 value) external returns (bool);
}
