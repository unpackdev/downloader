// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VFRPool.sol";

// solhint-disable no-empty-blocks
contract VFRCoveragePool is VFRPool {
    string public constant VERSION = "3.0.4";

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) VFRPool(_name, _symbol, _token) {}
}
