// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./draft-ERC20Permit.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title Bribe ERC20 Token
/// @author contact@bribe.xyz
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

contract BribeToken is ERC20Permit {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        _mint(msg.sender, totalSupply_);
    }
}
