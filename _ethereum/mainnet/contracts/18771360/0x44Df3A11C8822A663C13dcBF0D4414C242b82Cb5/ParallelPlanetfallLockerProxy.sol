pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "./IERC1155.sol";
import "./ERC1155LockerProxy.sol";

/// @title The Parallel Planetfall Locker Proxy contract.
/// @notice Used for bridging Parallel Planetfall nfts.
contract ParallelPlanetfallLockerProxy is ERC1155LockerProxy {
    /**
     * @param _router Router address
     * @param _erc1155 Erc1155 address
     */
    constructor(
        address _router,
        IERC1155 _erc1155
    ) ERC1155LockerProxy(_router, _erc1155) {}
}
