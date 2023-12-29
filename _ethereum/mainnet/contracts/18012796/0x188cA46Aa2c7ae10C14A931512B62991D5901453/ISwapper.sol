// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISwapper {
    function swap(address[] calldata tokens, bytes[] calldata callDatas) external;
}
