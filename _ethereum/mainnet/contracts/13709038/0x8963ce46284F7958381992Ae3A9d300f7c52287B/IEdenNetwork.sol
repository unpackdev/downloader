// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEdenNetwork {
    function stakeFor(address recipient, uint128 amount) external;
}
