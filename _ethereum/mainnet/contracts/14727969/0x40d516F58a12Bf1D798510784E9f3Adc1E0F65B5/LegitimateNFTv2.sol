// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Strings.sol"; 
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";

contract LegitimateLockedNFTV2 is ERC721Royalty, ERC721Enumerable, Ownable {
    using Strings for uint256;

    constructor() ERC721("LegitimateLockedNFTV2", "LGTNFT") {}

    mapping(uint256 => bool) tokenLock;

    // URI FUNCTIONS
    string baseURI = "https://metadata-api.legitimate.tech";

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory contractAddress = Strings.toHexString(uint160(address(this)), 20);

        string memory baseTokenUri = bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "/nfts/", contractAddress, "/", tokenId.toString(), "/metadata")) : "";

        if (tokenLock[tokenId]) {
          return string(abi.encodePacked(baseTokenUri, "/locked"));
        }

        return baseTokenUri;
    }

    // TOKENLOCK FUNCTIONS
    function _setTokenLock(uint256 tokenId, bool locked) internal {
      tokenLock[tokenId] = locked;
    }

    function setTokenLock(uint256 tokenId, bool locked) public onlyOwner {
      _setTokenLock(tokenId, locked);
    }

    // MINTING FUNCTIONS
    function mint(uint256 tokenId) public onlyOwner {
        _safeMint(msg.sender, tokenId);
    }

    function mint(uint256 tokenId, address to) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function mint(uint256 tokenId, address to, address feeReceiver, uint96 feeNumerator) public onlyOwner {
      _safeMint(to, tokenId);
      _setTokenRoyalty(tokenId, feeReceiver, feeNumerator);
    }

    // ROYALTY FUNCTIONS
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
      _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
      _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
      _deleteDefaultRoyalty();
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
      _resetTokenRoyalty(tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) override(ERC721) internal {
      super._afterTokenTransfer(from, to, tokenId);
      // Lock the NFT to indicate a transfer
      _setTokenLock(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}
