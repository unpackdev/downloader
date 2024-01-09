// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

import "./ERC777.sol";

/// @title Cryptopia Token 
/// @notice Game currency used in Cryptoipa
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaToken is ERC777 {

    /// @dev Contract Initializer
    constructor() ERC777("Cryptopia Token", "CRT", new address[](0))
    {
        _mint(msg.sender, 10_000_000_000 * 10 ** decimals(), "", "");
    }
}