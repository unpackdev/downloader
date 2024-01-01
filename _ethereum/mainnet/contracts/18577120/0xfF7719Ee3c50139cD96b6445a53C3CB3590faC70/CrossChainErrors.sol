// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./EnumTypes.sol";

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

import "./EnumTypes.sol";

/**************************************

    Cross-chain errors
    
**************************************/

/// @dev All errors used in cross chain communication
library CrossChainErrors {
    // -----------------------------------------------------------------------
    //                              Chain id & Provider
    // -----------------------------------------------------------------------

    error InvalidChainId(uint256 current, uint256 expected); // 0x9fba672f
    error UnsupportedChainId(uint256 chainId); // 0xa5dab5fe
    error ProviderChainIdMismatch(EnumTypes.CrossChainProvider provider, uint256 requestChainId, uint256 blockChainId); // 0x72c80f07
    error UnsupportedProvider(); // 0x7f4d001d

    // -----------------------------------------------------------------------
    //                              Payload
    // -----------------------------------------------------------------------

    error EmptyPayload(); // 0x2e3f1f34
}
