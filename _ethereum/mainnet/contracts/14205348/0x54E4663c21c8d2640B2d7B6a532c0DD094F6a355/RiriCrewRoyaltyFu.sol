// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PaymentSplitterMod.sol";

contract RiriCrewRoyaltyFu is PaymentSplitterMod {
    address[] private addressList = [
        0xC369e19708Cb7cdabE7a1B6fc4E6b3c53Cc348d9,
        0x1524cB831321D55eB3F42aab18991650C732d2Aa,
        0x87EAAEc2a77D3F2A3102d5Fb8B8f767fC2A8D8e3,
        0x7a991F4D736BD12bbE6bFddcac545910D69c9A80,
        0xb96936E9a5669246F39DCB806A390603ADFC8096,
        0x4395C5e578C7EF50ACE6e45292553AA9655e6FCF
    ];

    uint256[] private sharesList = [25, 33, 16, 16, 7, 3];

    constructor() PaymentSplitterMod(addressList, sharesList) {}
}
