//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Exchange.sol";

/**
 * @title OasisXExchange
 * @notice Exchange contract
 * @author OasisX Protocol | cryptoware.eth
 */
contract OasisXExchange is Exchange {
    /// @notice contract name and version
    string public constant name = "OasisX Exchange";
    string public constant version = "1.0";

    /**
     * Initializes the exchange and migrates the registries
     * @param registryAddrs a list of the registries that this exchange will be compatible with. Must be mutual (i.e. this exchange must be an approved caller of the registry and vice versa)
     * @param protocolFeeRecipient protocol fee relayer
     * @param pFee_ fee amount
     */
    constructor(
        address[] memory registryAddrs,
        address protocolFeeRecipient,
        ProtocolFee memory pFee_
    ) Exchange(name, version, protocolFeeRecipient, pFee_) {
        require
        (
            registryAddrs.length > 0,
            "OasisXExchange: At least add one registry address"
        );

        require
        (
            protocolFeeRecipient != address(0),
            "OasisXExchange: Address cannot be 0"
        );
        
        for (uint256 ind = 0; ind < registryAddrs.length; ind++) {
            registries[registryAddrs[ind]] = true;
        }
    }
}
