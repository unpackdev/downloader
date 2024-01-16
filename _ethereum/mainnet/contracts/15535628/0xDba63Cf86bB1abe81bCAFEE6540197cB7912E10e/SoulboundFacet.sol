// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlModifiers.sol";
import "./PausableModifiers.sol";
import "./TransferHooksLib.sol";
import "./OverrideModifiers.sol";
import "./console.sol";

contract SoulboundFacet is
    AccessControlModifiers,
    PausableModifiers,
    OverrideModifiers
{
    // the selector for soulboundBeforeTransferHook(address,address,uint256,uint256)
    bytes4 constant SOULBOUND_TRANSFER_HOOK_SELECTOR = 0xe88716a1;

    function enableSoulbound() public whenNotPaused onlyOwner {
        TransferHooksLib.setBeforeTransfersHook(
            SOULBOUND_TRANSFER_HOOK_SELECTOR
        );
    }

    function disableSoulbound() public whenNotPaused onlyOwner {
        TransferHooksLib.removeBeforeTransfersHook();
    }

    function soulboundBeforeTransferHook(
        address from,
        address to,
        uint256,
        uint256
    ) public view isOverride {
        if (from != address(0) && to != address(0))
            revert("Soulbound: Cannot Transfer Token");
    }

    function isSoulboundEnabled() public view returns (bool) {
        return
            TransferHooksLib.transferHooksStorage().beforeTransfersHook ==
            SOULBOUND_TRANSFER_HOOK_SELECTOR;
    }
}
