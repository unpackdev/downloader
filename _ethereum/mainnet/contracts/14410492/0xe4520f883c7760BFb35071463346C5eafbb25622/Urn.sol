// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

/// @title Graveyard NFT Project's URN Token
/// @author @0xyamyam
/// @notice URN tokens have no specified utility or value, who knows what the future holds.
/// URN tokens are minted when you commit failed NFT project tokens to the Graveyard (more if you own a CRYPT).
contract Urn is ERC20("URN", "URN"), ERC20Permit("URN"), ERC20Burnable, ReentrancyGuard, Ownable(5, true, true) {
    /// Track controller contracts and their permissions
    mapping(address => bool) private _controllers;

    /// Authorises known addresses to mint URN tokens.
    /// @param contractAddress The address to associate permissions
    /// @param canMint Is the address allowed to mint URN
    function setController(address contractAddress, bool canMint) external onlyOwner {
        require(Address.isContract(contractAddress), "Only contracts can be added as controllers");
        _controllers[contractAddress] = canMint;
    }

    /// Mint URN Tokens from controllers
    /// @param to The address to mint tokens for
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external nonReentrant {
        require(_controllers[_msgSender()] == true, "Only controllers with mint permissions can mint URN");
        _mint(to, amount);
    }
}
