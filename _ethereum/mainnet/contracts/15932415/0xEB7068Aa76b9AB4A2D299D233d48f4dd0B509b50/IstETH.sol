/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IstETH {
    function submit(uint256 amount) external returns (uint256 value);
}
