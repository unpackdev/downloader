// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BridgeBase.sol";

contract BridgeEth is BridgeBase {
    constructor(
        address owner_,
        address admin_,
        address refundManager_,
        address[] memory signers_,
        address token,
        address blocklist_
    ) BridgeBase(owner_, admin_, refundManager_, signers_, token, blocklist_, "ETH_KALE_BRIDGE") {}
}
