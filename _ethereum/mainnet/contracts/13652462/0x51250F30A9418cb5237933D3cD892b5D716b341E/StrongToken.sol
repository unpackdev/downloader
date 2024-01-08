pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

import "./ERC20Burnable.sol";

/// @title USA Strong token contract
/// @author USA Strong team

contract StrongToken is ERC20Burnable {
    // @note The vault to receive all minted tokens.
    address public immutable tokenVault;

    /// @dev Constructor will set the parameters of the ERC-20 token (name, symbol) and mint to the token vault.
    /// @param _tokenVault - Address will receive all minted tokens
    constructor(address _tokenVault) ERC20("USA Strong", "USA") {
        tokenVault = _tokenVault;
        _mint(_tokenVault, 10 * 1e9 * 1e18); // Total supply = 10B tokens
    }
}
