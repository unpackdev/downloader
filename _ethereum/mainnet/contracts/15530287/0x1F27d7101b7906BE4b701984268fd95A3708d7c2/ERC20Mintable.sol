// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title ERC20Mintable
/// @author D3Y3R, Kyoko Kirigiri
/// @notice ERC20 for ether and ETHW IOUs deployed by and owned by ForkIOU contract
contract ERC20Mintable is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Mint new tokens when issuing IOUs
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    /// @notice Burn IOUs to redeem ether or ETHW
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}
