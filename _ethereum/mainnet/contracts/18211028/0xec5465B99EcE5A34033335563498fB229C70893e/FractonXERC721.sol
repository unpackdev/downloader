// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IFractonXERC721.sol";

contract FractonXERC721 is IFractonXERC721, ERC721, Ownable {

    uint256 public tokenId;
    uint256 public totalSupply;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function mint(address to) external onlyOwner returns(uint256 curTokenId){
        curTokenId = tokenId;
        _safeMint(to, tokenId);
        tokenId += 1;
        totalSupply += 1;
    }

    function burn(uint256 tokenid) external onlyOwner {
        _burn(tokenid);
        totalSupply -= 1;
    }
}
