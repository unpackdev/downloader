// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC1967Proxy.sol";

contract KFNC1967Proxy is ERC1967Proxy {
    constructor(address logic_, bytes memory data_) ERC1967Proxy(logic_, data_) payable {}
}
