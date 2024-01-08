// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./ERC1967Proxy.sol";

/**
 * @title HidingVaultNFT's UUPS Proxy
 * @author KeeperDAO
 */
contract HidingVaultNFTProxy is ERC1967Proxy {
    constructor(address _implementation, address _defaultOwner, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}