// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./IBeforeTokenTransferHandler.sol";
import "./Ownable.sol";
import "./OperatorFilterRegistry.sol";

/**
 * A before transfer hook that uses OpenSea's marketplace blocking registry.
 */
contract FilterRegistryHook is IBeforeTokenTransferHandler, Ownable {
    error OperatorNotAllowed(address operator);
    OperatorFilterRegistry operatorFilterRegistry;

    /**
     * Get the address of the filter registry we're using.
     */
    function getFilterRegistry() external view onlyOwner returns (address) {
        return address(operatorFilterRegistry);
    }

    /**
     * Set the filter registry to a specific address.
     */
    function setFilterRegistry(address newRegistry) external onlyOwner {
        operatorFilterRegistry = OperatorFilterRegistry(newRegistry);
    }

    /**
     * Handles before token transfer events from a ERC721 contract
     */
    function beforeTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 tokenId
    ) external {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (
                !(
                    operatorFilterRegistry.isOperatorAllowed(
                        tokenContract,
                        operator
                    )
                )
            ) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}
