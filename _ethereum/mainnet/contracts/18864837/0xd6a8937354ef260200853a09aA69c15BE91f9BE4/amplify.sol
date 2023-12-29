// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract AMPLIFY is ERC20, Ownable {
    uint256 private immutable _maxSupply = 300000000000 * (10 ** decimals());

    constructor() ERC20("AMPLIFY", "AMPS") Ownable(msg.sender) { // Pass the deployer's address to the Ownable constructor.
        _mint(msg.sender, _maxSupply); // Mint the total supply to the contract owner.
    }

    function distributeRewards(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        require(recipients.length == amounts.length, "Mismatched arrays");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    // Burn tokens to reduce the supply if needed.
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}
