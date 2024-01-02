
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract SamBack is ERC20, Ownable {


    constructor(uint256 initialSupply)
    ERC20("SamAltman", "SamAltman") Ownable() {
        _mint(msg.sender, initialSupply * 10 ** decimals());

    }

    // airdrop tokens to initial community members, CEX listings, dev & marketing wallets.
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
    require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

    for (uint256 i = 0; i < recipients.length; i++) {
        transfer(recipients[i], amounts[i]);
    }
}
}
