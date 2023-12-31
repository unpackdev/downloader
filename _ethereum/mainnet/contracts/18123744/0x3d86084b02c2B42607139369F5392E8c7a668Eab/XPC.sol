/**
*/
// SPDX-License-Identifier: Unlicensed

// https://xpaycoin.net/
// https://twitter.com/XPayCommunity
//⠀https://t.me/XPayCoinportal

pragma solidity 0.8.17;

import "./ContractBase.sol";

contract XPC is ContractBase {
    constructor() ContractBase(
        address(0xa6B9eC2f49dAcb10efAb959E32707c97738d553a), //marketing wallet
        address(0xe22F27d28A31EdbAe1c4b78F95451C03369604f9), //dev wallet
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), //dex router address
        "XPAY Coin",
        "XPC") {
    } 
} 
