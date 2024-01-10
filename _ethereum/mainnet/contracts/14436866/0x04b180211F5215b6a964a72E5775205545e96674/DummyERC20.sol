// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./IMKLockRegistry.sol";

contract DummyToken is ERC20 {
    IMKLockRegistry public monkey;

    constructor(uint256 initialSupply) ERC20("DummyToken", "DTK") {
        _mint(msg.sender, initialSupply);
    }

    // in production this needs onlyOwner
    function setMonkey(address addr) public {
        monkey = IMKLockRegistry(addr);
    }

    function lockMonkey(uint256 tokenId) public {
        monkey.lock(tokenId);
    }

    function unlockMonkey(uint256 tokenId, uint256 pos) public {
        monkey.unlock(tokenId, pos);
    }
}
