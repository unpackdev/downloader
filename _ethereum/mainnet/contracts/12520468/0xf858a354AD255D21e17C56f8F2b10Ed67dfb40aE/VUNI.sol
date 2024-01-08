// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VTokenBase.sol";

//solhint-disable no-empty-blocks
contract VUNI is VTokenBase {
    string public constant VERSION = "3.0.2";

    // UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
    constructor() VTokenBase("vUNI Pool", "vUNI", 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984) {}
}
