// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

import "./Ownable.sol";

/// @custom:security-contact info@afrika.dev
contract DrivesToken is ERC20, Ownable {
    constructor(address newOwner) ERC20("Drive Club", "DRIVES") {
        _mint(newOwner, 5000000 * 10 ** decimals());
        _transferOwnership(newOwner);
    }
}
