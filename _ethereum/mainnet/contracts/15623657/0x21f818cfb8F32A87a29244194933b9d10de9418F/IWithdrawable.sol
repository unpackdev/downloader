// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

interface IWithdrawable {
    function withdraw(uint wad) external;
}
