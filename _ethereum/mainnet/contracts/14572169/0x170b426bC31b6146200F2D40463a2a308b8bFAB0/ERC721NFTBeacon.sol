// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./UpgradeableBeacon.sol";

contract ERC721NFTBeacon is UpgradeableBeacon {
    bytes4 constant identifier = bytes4(keccak256("erc721"));

    constructor(address impl) UpgradeableBeacon(impl) {}
}
