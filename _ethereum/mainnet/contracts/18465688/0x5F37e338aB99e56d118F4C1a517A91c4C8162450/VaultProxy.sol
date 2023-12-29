// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1967Proxy.sol";


contract VaultProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) payable {}

    // Simply accept ETH transfers.
    // Delegating to the implementation (which is default) results in `outOfGas`.
    receive() external payable override {}
}