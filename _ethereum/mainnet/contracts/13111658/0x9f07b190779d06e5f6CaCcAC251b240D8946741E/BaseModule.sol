// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

abstract contract BaseModule {
    address public mothership;

    modifier onlyMothership {
        require(msg.sender == mothership, "Access restricted to mothership");
        _;
    }

    constructor(address _mothership) public {
        mothership = _mothership;
    }
}