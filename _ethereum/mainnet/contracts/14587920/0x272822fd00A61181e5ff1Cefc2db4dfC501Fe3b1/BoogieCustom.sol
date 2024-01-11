// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract BoogieCustom is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _contractURI;
    string private diamondURI;
    uint256 public mintRate = 0.1 ether;

    constructor() ERC721("BoogieVanCustomShop", "BV") {}

    function adminMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenIdCounter.increment();
    }

    function diamondMint(uint256 amount) public payable nonReentrant {
        require(balanceOf(msg.sender) < 3, 'Max 3 Tokens per wallet');
        require(msg.value >= amount * mintRate, "Not enough ether.");
        address to = msg.sender;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _setTokenURI(_tokenIdCounter.current(), diamondURI);
            _tokenIdCounter.increment();
        }
    }


    function setMintRate(uint256 amount) public onlyOwner {
        mintRate = amount;
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function setDiamondURI(string memory uri) public onlyOwner {
        diamondURI = uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    function withdraw() public onlyOwner{
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}
