// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract WastingETH is ERC721A {

    uint256 public pricePerNFT = 0.00001 ether;

    constructor() ERC721A("WastingETH", "WETH") {}

    function mint(uint256 _amount) 
        external 
        payable 
    {
        _safeMint(msg.sender, _amount);
    }
}
