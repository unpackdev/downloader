// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";

contract SmartWalletChecker is Ownable {
    mapping(address => bool) public whitelist;

    constructor() {
        _transferOwnership(0x6D5a7597896A703Fe8c85775B23395a48f971305);
        whitelist[0x6D5a7597896A703Fe8c85775B23395a48f971305] = true;
    }

    function setWhitelist(address _addr, bool _whitelisted) external onlyOwner {
        whitelist[_addr] = _whitelisted;
    }

    function check(address _addr) public view returns (bool) {
        return whitelist[_addr];
    }
}
