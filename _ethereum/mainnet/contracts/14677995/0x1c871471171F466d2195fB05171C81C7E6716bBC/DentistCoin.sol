// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/// @title DentistCoin ERC20 contract
contract DentistCoin is ERC20, ERC20Burnable, Pausable, Ownable {
    /// @notice Contract constructor which initializes on ERC20 core implementation and mints 5.21 billion tokens to deployer/owner
    constructor() ERC20("DentistCoin", "DEN") {
        _mint(msg.sender, 5210000000 * 10**decimals());
    }

    /// @notice Owner functionality to pause token transfers and token burns until unpaused by owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Owner functionality to unpause token transfers and token burns if already paused by owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Hook that is called before any transfer of tokens. Overridden to incorporate pause/unpause functionality
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
