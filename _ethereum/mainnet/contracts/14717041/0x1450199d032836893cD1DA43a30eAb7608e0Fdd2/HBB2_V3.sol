// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./OwnableUpgradeable.sol";
import "./HBB2.sol";

contract HBB2_V3 is
    HBB2,
    OwnableUpgradeable
{

    function initializeV4() public {
        require(version == "1.0", "Initialize function already executed"); 
        version = "2.0";

        _transferOwnership(0x3e869bD6a0829D9b2b6a0A979008Ee655D4E9cFD);

    }
}
