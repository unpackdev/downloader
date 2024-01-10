// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SolidarityMetadataBase.sol";

/**
 * @title Solidarity Metadata wrapper contract
 */
contract SolidarityMetadata is SolidarityMetadataBase {
    constructor()
        SolidarityMetadataBase(
            'ipfs://',
            'QmT6Em9Dt7RzritFvrvW5CVwvZgp6GE94RxAsnGCuShyiz', // Valeriia Unfurling Final V1.0.0
            'QmXWdy9J7fh3cYDTdpYrLGxa9KXTHLMdNF2729PBmom2f4' // Valeriia Final V1.0.0
        )
    {
        // Implementation version: 1
    }
}
