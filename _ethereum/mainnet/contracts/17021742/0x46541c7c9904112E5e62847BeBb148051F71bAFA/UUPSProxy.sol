// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./UUPSUpgradeable.sol";
import "./ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}
