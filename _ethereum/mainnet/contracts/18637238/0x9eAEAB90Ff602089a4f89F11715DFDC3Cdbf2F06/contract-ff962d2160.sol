// SPDX-License-Identifier: FCKCRYPTO
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact fckcryptoeth@proton.me
contract FCKCRYPTO is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("FCKCRYPTO", "FCKCRYPTO")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
