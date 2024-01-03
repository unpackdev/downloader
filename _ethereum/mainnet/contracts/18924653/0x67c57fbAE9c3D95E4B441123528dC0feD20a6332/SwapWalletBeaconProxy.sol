// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BeaconProxy.sol";

contract SwapWalletBeaconProxy is BeaconProxy {
    constructor(address beacon, bytes memory data) BeaconProxy(beacon, data) payable {

    }
    receive() override external payable {  // Need this to make convertFromWETH in SwapWallet work
            // React to receiving ether
    }
}

