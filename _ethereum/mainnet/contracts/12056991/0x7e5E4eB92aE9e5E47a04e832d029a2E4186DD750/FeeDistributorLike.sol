// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

abstract contract FeeDistributorLike {
    function distributeFees() public virtual;
}
