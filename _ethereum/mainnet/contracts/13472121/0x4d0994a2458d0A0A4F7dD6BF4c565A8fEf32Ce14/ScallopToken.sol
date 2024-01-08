// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20Permit.sol";

/**
 * Implementation of the Scallop token
 */
contract ScallopToken is ERC20, Pausable, ERC20Permit, Ownable {
    bool public initialized = false;

    constructor() {}

    function initialize(address owner) external payable {
        require(!initialized, "already initialized");

        initializeERC20("ScallopX", "SCLP");
        initializePausable();
        initializeOwnable(owner);
        initializeERC20Permit("ScallopX");

        _mint(owner, 100000000 * 1e18); // mint 100 mil SCLP tokens
        initialized = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function togglePause() external onlyOwner {
        if (!paused()) _pause();
        else _unpause();
    }
}
