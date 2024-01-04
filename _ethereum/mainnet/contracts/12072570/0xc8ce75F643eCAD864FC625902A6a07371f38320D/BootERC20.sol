// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BootERC20 is ERC20 {

    string private constant _tokenName = "Bootleg NFT";
    string private constant _tokenSymbol = "BOOT";
    uint256 private constant INITIAL_SUPPLY = 15000000000000000000000000;

    constructor() ERC20(_tokenName, _tokenSymbol) {
      _mint(msg.sender, INITIAL_SUPPLY);
    }

}
