// SPDX-License-Identifier: UNLICENSED
// Zaap.exchange Contracts (Zaap.sol)
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./Pausable.sol";

import "./NativeWrapper.sol";
import "./Swapper.sol";
import "./ZaapIn.sol";
import "./ZaapOut.sol";

import "./IWETH9.sol";
import "./IStargateRouter.sol";
import "./IPermit2.sol";
import "./IAllowanceTransfer.sol";

contract Zaap is NativeWrapper, Swapper, ZaapIn, ZaapOut {
    constructor(
        IWETH9 wETH9_,
        address swapRouter02Address_,
        IStargateRouter stargateRouter_,
        IPermit2 permit2_
    ) NativeWrapper(wETH9_) Swapper(swapRouter02Address_) ZaapIn(stargateRouter_, permit2_) ZaapOut(address(stargateRouter_)) {}
}
