// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NewCryptoPigs is ERC721, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint public maxSupply = 4791;
    uint public price=0.09 ether;

    constructor() ERC721("NewCryptoPigs", "NCP") {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner(), tokenId);
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.newcryptopigs.com/contract/metadata.json";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeihwzabvevqqzdybinbprjsujle5xbjx2x6sqz7ge4qvjxtp3xbyam/";
    }

    function safeMint(uint amount) public payable {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value >= price*amount, "Incorrect amount (price)");
        require(_tokenIdCounter.current() + amount <= maxSupply, "Max Supply Reached");
        for(uint i = 0; i < amount; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(owner(), tokenId);
            _transfer(owner(), msg.sender, tokenId);
        }
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
