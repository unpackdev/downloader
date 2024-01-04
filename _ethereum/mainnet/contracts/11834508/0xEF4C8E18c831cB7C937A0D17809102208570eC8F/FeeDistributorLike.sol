// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract FeeDistributorLike {
    function distributeFees() public virtual;
}
