// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title LendingPoolToken
/// @author Florence Finance
/// @dev Every LendingPool has its own LendingPoolToken which can be minted and burned by the LendingPool
contract LendingPoolToken is ERC20, Ownable {
    /// @dev
    /// @param _lendingPoolId (uint256) id of the LendingPool this token belongs to
    /// @param _name (string) name of the token (see ERC20)
    /// @param _symbol (string) symbol of the token (see ERC20)
    // solhint-disable-next-line
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @dev Allows owner to mint tokens.
    /// @param _receiver (address) receiver of the minted tokens
    /// @param _amount (uint256) the amount to mint (18 decimals)
    function mint(address _receiver, uint256 _amount) external onlyOwner {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _mint(_receiver, _amount);
    }

    /// @dev Allows owner to burn tokens.
    /// @param _amount (uint256) the amount to burn (18 decimals)
    function burn(uint256 _amount) external {
        require(_amount > 0, "LendingPoolToken: invalidAmount");
        _burn(msg.sender, _amount);
    }
}
