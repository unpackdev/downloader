//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

    ███████╗██████╗  █████╗ ███╗   ██╗██╗  ██╗
    ██╔════╝██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝
    ███████╗██████╔╝███████║██╔██╗ ██║█████╔╝
    ╚════██║██╔═══╝ ██╔══██║██║╚██╗██║██╔═██╗
    ███████║██║     ██║  ██║██║ ╚████║██║  ██╗
    ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝

            Planktoons ERC-20 token
             https://planktoons.io

*/

import "./ERC20.sol";
import "./Ownable.sol";

/// @notice Planktoons $SPANK token
contract SPANK is ERC20, Ownable {
    constructor() ERC20("SPANK", "SPANK") {}

    /// @notice Mint tokens to msg sender. Only callable by owner
    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
