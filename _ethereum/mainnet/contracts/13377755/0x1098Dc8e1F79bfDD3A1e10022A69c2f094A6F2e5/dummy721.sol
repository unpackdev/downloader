pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract PunkCouponZ is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string base = "ipfs://QmXCV43bt4fZxRWKSmvzZmrdCyFC9Cj7V8PTKWkpfoZsD3/";
    constructor() ERC721("Punk Coupons","PNKCPN"){
        
    }

    function mint(address to, uint256[] memory tokenIds) external onlyOwner{
        for (uint j = 0; j < tokenIds.length; j++) {
            _mint(to,tokenIds[j]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }



}