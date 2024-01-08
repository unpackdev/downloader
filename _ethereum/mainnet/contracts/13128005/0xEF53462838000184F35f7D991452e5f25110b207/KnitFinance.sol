// SPDX-License-Identifier: NFT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract KnitFinance is ERC20, Ownable {

    constructor(uint256 initialSupply) ERC20("Knit Finance", "KFT") {
        _mint(msg.sender, initialSupply);
    }
}
