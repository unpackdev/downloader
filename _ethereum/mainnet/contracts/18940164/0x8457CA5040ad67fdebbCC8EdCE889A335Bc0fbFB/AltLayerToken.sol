// SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ERC20Capped.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";

/// @title AltLayer Token Contract
/// @notice Implements an ERC20 token with a cap, burnability, pausability, and ownership features
contract AltLayerToken is
    ERC20Burnable,
    ERC20Permit,
    ERC20Capped,
    ERC20Pausable,
    Ownable
{
    /// @notice Initializes the contract with a name, symbol, cap, and initial owner
    /// @param initialOwner The address to be set as the initial owner of the token
    constructor(
        address initialOwner
    )
        ERC20("AltLayer Token", "ALT")
        ERC20Permit("AltLayer Token")
        ERC20Capped(1e28)
        Ownable(initialOwner)
    {}

    /// @notice Allows the owner to pause all token transfers
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to mint new tokens, up to the cap
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @dev Internal function to update state during transfers, respecting the cap and pausability
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param value The amount of tokens being transferred
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Capped, ERC20Pausable) {
        super._update(from, to, value);
    }
}
