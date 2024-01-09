// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

/*
   _____                          __   _____ __         ____    
  / ___/____ ______________  ____/ /  / ___// /____  __/ / /____
  \__ \/ __ `/ ___/ ___/ _ \/ __  /   \__ \/ //_/ / / / / / ___/
 ___/ / /_/ / /__/ /  /  __/ /_/ /   ___/ / ,< / /_/ / / (__  ) 
/____/\__,_/\___/_/   \___/\__,_/   /____/_/|_|\__,_/_/_/____/  

I see you nerd! ⌐⊙_⊙
*/

contract GenesisSacredSkulls is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    string public provenance;

    bool public isLocked = false;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        //
    }

    /*
    * Lock provenance and base URI.
    */
    function lockProvenance() public onlyOwner {
        isLocked = true;
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {
        require(!isLocked, "Locked");        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!isLocked, "Locked");
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!isLocked, "Locked");
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
