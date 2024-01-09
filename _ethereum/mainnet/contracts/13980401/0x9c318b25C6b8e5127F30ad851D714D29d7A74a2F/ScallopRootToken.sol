// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20Permit.sol";

/**
 * Implementation of the Scallop token
 */
contract ScallopRootToken is ERC20, Pausable, ERC20Permit, Ownable {
    bool public initialized;

    function initialize(address owner) external payable {
        require(!initialized, "already initialized");

        initializeERC20("Scallop", "SCLP");
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
        require(address(to) != address(this), "dont send to token contract");
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function name() public view virtual override returns (string memory) {
        return "Scallop";
    }

    function refundTokens() external onlyOwner {
        _transfer(address(this), owner(), balanceOf(address(this)));
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function togglePause() external onlyOwner {
        if (!paused()) _pause();
        else _unpause();
    }
}
