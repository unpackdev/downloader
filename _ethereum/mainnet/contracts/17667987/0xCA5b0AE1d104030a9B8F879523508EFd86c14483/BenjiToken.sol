// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IForwarderRegistry.sol";
import "./ERC20.sol";
import "./ERC20Storage.sol";
import "./ERC20Detailed.sol";
import "./ERC20Metadata.sol";
import "./ERC20Permit.sol";
import "./ERC20SafeTransfers.sol";
import "./ERC20BatchTransfers.sol";
import "./TokenRecovery.sol";
import "./ContractOwnership.sol";
import "./Context.sol";
import "./ForwarderRegistryContextBase.sol";
import "./ForwarderRegistryContext.sol";

contract BenjiToken is
    ERC20,
    ERC20Detailed,
    ERC20Metadata,
    ERC20SafeTransfers,
    ERC20BatchTransfers,
    ERC20Permit,
    ForwarderRegistryContext,
    TokenRecovery
{
    using ERC20Storage for ERC20Storage.Layout;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address[] memory initialHolders,
        uint256[] memory mintAmounts,
        IForwarderRegistry forwarderRegistry
    ) ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) ForwarderRegistryContext(forwarderRegistry) ContractOwnership(msg.sender) {
        ERC20Storage.layout().batchMint(initialHolders, mintAmounts);
    }

    function _msgSender() internal view virtual override(Context, ForwarderRegistryContextBase) returns (address) {
        return ForwarderRegistryContextBase._msgSender();
    }

    function _msgData() internal view virtual override(Context, ForwarderRegistryContextBase) returns (bytes calldata) {
        return ForwarderRegistryContextBase._msgData();
    }
}
