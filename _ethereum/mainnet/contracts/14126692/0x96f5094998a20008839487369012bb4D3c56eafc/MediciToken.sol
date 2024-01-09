// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC20Capped.sol";
import "./Ownable.sol";

/// @title MediciToken
/// @dev Florence Finance Governance Token
contract MediciToken is Ownable, ERC20Capped {
    /// @dev Initialize with name 'Medici Token', symbol 'MDC' and 1 billion supply cap
    constructor() ERC20("Medici Token", "MDC") ERC20Capped(1_000_000_000 * 10**18) {}

    /// @dev Allows owner to mint MDC tokens.
    /// @param _receiver (address) address to receive the tokens
    /// @param _amount (uint256) amount to mint (18 decimals)
    function mint(address _receiver, uint256 _amount) external onlyOwner {
        require(_amount > 0, "MediciToken: invalidAmount");
        _mint(_receiver, _amount);
    }

    /// @dev Allows anyone to burn their own MDC tokens
    /// @param _amount (uint256) amount to burn (18 decimals)
    function burn(uint256 _amount) external {
        require(_amount > 0, "MediciToken: invalidAmount");
        _burn(msg.sender, _amount);
    }
}
