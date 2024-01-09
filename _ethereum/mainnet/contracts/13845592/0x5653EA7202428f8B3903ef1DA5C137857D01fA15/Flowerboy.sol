// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Flowerboy is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    uint256 mintCap = 10000;
    string baseURI;

    event NFTMinted(uint256[] idNumber);
    event NFTsBurnt(uint256 newIdNumber, uint256 newMintCap);

    constructor(string memory myBaseURI) ERC721("Flowerboy", "FLB") {
        baseURI = (myBaseURI);
    }

    function setBaseURI(string memory myBaseURI) external onlyOwner {
        baseURI = myBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getFlowerboysMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getMintCap() public view returns (uint256) {
        return mintCap;
    }

    function changeTokenURI(uint256 tokenId, string memory newTokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, newTokenURI);
    }

    function mintFlowerboys(uint256 amountToMint) public payable {
        require(
            amountToMint < 6 && amountToMint > 0,
            "Invalid amount requested"
        );
        require(
            _tokenIdCounter.current() + amountToMint <= mintCap,
            "Mint cap has been reached"
        );
        require(
            msg.value == (0.1 ether) * amountToMint,
            "Not enough ether was sent"
        );

        uint256[] memory mintedIDs = new uint256[](amountToMint);

        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 itemID = _tokenIdCounter.current() + 1;
            _tokenIdCounter.increment();
            _safeMint(msg.sender, itemID);
            _setTokenURI(itemID, itemID.toString());
            mintedIDs[i] = itemID;
        }

        emit NFTMinted(mintedIDs);
    }

    function burnFlowerboys(uint256 tokenId1, uint256 tokenId2) public {
        require(ownerOf(tokenId1) == msg.sender, "Sender does not own NFT");
        require(ownerOf(tokenId2) == msg.sender, "Sender does not own NFT");
        _burn(tokenId1);
        _burn(tokenId2);
        uint256 itemID = _tokenIdCounter.current() + 1;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, itemID);
        _setTokenURI(itemID, itemID.toString());
        mintCap += 1;
        emit NFTsBurnt(itemID, mintCap);
    }

    function getOwnedFlowerboys() public view returns (string[] memory) {
        uint256 amountOfTokens = balanceOf(msg.sender);
        string[] memory ownedTokenURLs = new string[](amountOfTokens);
        for (uint256 i = 0; i < amountOfTokens; i++) {
            ownedTokenURLs[i] = tokenURI(tokenOfOwnerByIndex(msg.sender, i));
        }
        return ownedTokenURLs;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
