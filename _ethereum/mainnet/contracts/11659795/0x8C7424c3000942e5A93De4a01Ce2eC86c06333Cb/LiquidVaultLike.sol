// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

abstract contract LiquidVaultLike {
    function purchaseLP() public virtual;

    function claimLP() public virtual;

    function purchaseLPFor(address beneficiary) public payable virtual;
}
