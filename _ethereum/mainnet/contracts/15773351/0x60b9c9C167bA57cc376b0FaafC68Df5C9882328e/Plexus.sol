// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

contract Plexus is ERC20("Plexus", "PLX"), Ownable {
    /**
     * @notice Mint new tokens
     * @param to The address of the destination account
     * @param amount The number of tokens to be minted
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    constructor() public {
        uint256 initSupply = 5 * (10**8) * (10**18);
        _mint(owner(), initSupply);
    }
}
