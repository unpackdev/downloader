// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BAYFC is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public baseTokenURI;
    string public DiscordClub;
    uint256 public MaxFakeApes = 10000;

    constructor() ERC721("BoredApeYachtFakeClub", "BAYFC") {
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal onlyOwner override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory uri) public virtual onlyOwner {
        baseTokenURI = uri;
    }

    function setDiscordClub(string memory _i) public virtual onlyOwner {
        DiscordClub = _i;
    }
    
    function withdraw(address payable _to) public onlyOwner {
        uint amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function mint() public {
        require (_tokenIds.current() + 1 <= MaxFakeApes, "over max");

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();
    }

    function batchMint(uint256 count) public {
        require (_tokenIds.current() + 1 + count <= MaxFakeApes, "over max");
        
        for (uint i = 0; i < count; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }
    }
}
