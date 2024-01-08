//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./NPass.sol";
import "./IN.sol";

/**
 * @title nVn Car Cards Game For N
 * @author NFT GAMES SKG
 */
contract CarsNVN is NPass {
    bool public publicSale = false;
    using Strings for uint256;
    string public baseURI;

    constructor(string memory baseURI_) NPass("NVN", "nVn", false, 8888, 0, 15000000000000000, 15000000000000000) {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }

    function setPublicSale(bool _publicSale) public onlyOwner {
        publicSale = _publicSale;
    }

    function mint(uint256 tokenId) public payable override nonReentrant {
        require(publicSale, "NPass:OPEN_MINTING_DISABLED");
        require(openMintsAvailable() > 0, "NPass:MAX_ALLOCATION_REACHED");
        require(tokenId > 0 && tokenId <= maxTotalSupply, "Token ID invalid");
        require(msg.value == priceForOpenMintInWei, "NPass:INVALID_PRICE");

        _safeMint(msg.sender, tokenId);
    }
   
}
