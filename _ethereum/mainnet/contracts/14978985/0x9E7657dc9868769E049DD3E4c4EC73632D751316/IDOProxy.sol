// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./UpgradableProxy.sol";

contract IDOProxy is UpgradableProxy {
    constructor(address _implementation, address owner)
        UpgradableProxy(_implementation, owner)
    {}
}
