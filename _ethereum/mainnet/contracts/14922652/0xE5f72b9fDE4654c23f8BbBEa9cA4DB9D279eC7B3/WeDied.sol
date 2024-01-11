/*

 ▄▀▀▄    ▄▀▀▄  ▄▀▀█▄▄▄▄      ▄▀▀█▄▄   ▄▀▀█▀▄   ▄▀▀█▄▄▄▄  ▄▀▀█▄▄  
█   █    ▐  █ ▐  ▄▀   ▐     █ ▄▀   █ █   █  █ ▐  ▄▀   ▐ █ ▄▀   █ 
▐  █        █   █▄▄▄▄▄      ▐ █    █ ▐   █  ▐   █▄▄▄▄▄  ▐ █    █ 
  █   ▄    █    █    ▌        █    █     █      █    ▌    █    █ 
   ▀▄▀ ▀▄ ▄▀   ▄▀▄▄▄▄        ▄▀▄▄▄▄▀  ▄▀▀▀▀▀▄  ▄▀▄▄▄▄    ▄▀▄▄▄▄▀ 
         ▀     █    ▐       █     ▐  █       █ █    ▐   █     ▐  
               ▐            ▐        ▐       ▐ ▐        ▐        

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract WeDied is ERC721 {

    IERC721 WAGDIE = IERC721(0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A);

    error NotDead();
    error NotRevived();

    constructor() ERC721("We Died", "WEDIED") {}

    function mint(uint256 tokenId) public {
        if (
            WAGDIE.ownerOf(tokenId) !=
            address(0x000000000000000000000000000000000000dEaD)
        ) revert NotDead();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_ownerOf[tokenId] == address(0)) revert NotRevived();
        return WAGDIE.tokenURI(tokenId);
    }
}
