// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import needed packages
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

// create contract

contract transientNFT is ERC721, Ownable {
    // counter for token ids so always mint to a new NFT
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokenURI mapping
    mapping (uint256 => string) private _tokenURIs;

    // override construtor
    constructor() ERC721("Transient NFT", "TNFT") Ownable() {
    }
    // override tokenURI
    function tokenURI(uint256 tokenId) override public view returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // get token URI
        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "Transient NFT: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mintNFT(address recipient, string memory _tokenURI) public onlyOwner returns(uint256) {
        // increment token id
        _tokenIds.increment();

        // get new item id to return
        uint256 newItemId = _tokenIds.current();

        // mint NFT
        _safeMint(recipient, newItemId);

        // set NFT token URI
        _setTokenURI(newItemId, _tokenURI);

        // return new item id
        return newItemId;
        
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        // assign new token URI
        _setTokenURI(tokenId, _tokenURI);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transient NFT: Caller for burning is not approved nor owner");
        _burn(tokenId);
    }

}