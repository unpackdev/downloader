// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1967Proxy.sol";

contract EndstateNFTWrapperProxy is ERC1967Proxy {
    /// @notice Initializes the EndState NFT Wrapper proxy via UUPS.
    /// @param logic The address of the EndState NFT Wrapper implementation.
    /// @param data ABI-encoded EndState NFT Wrapper proxy initialization data.
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}
