// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./console.sol";

contract BootERC20 is ERC20, Ownable {

    string private constant _tokenName = "Bootleg NFT";
    string private constant _tokenSymbol = "BOOT";

    constructor() ERC20(_tokenName, _tokenSymbol) {
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}