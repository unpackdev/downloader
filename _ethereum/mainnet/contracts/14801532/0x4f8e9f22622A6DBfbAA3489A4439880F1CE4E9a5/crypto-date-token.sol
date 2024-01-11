// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20PresetFixedSupply.sol";

contract CryptoDateToken is ERC20PresetFixedSupply {
    constructor(uint256 totalSupply)
        ERC20PresetFixedSupply(
            "Cryptodate Token",
            "CDT",
            totalSupply,
            msg.sender
        )
    {}
}
