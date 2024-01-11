// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";


contract SevenSeas is ERC721, ERC721URIStorage, Pausable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MAX_TOKENS = 100000;

    event Minted(uint256 tokenID, string url);

    constructor() ERC721("7 Seas Meta", "7SEA") {}

    receive() external payable {}

    fallback() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Mint tokens  - ONLY OWNER CAN MINT THESE
    function safeMint(address to, string calldata url) public onlyOwner {

        // Must meet all conditions to mint a new token
        require(_tokenIdCounter.current() <= MAX_TOKENS, "Mint would exceed maximum number allowed by contract");


        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, url);
        emit Transfer(address(0), to, tokenId);
        emit Minted(tokenId, url);
    }

    // Anyone can query a token URI
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Owner can update URI of token
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    ////////////////////////////////////////////////////////////////////////////////////////
    // For owner to handle payments
    function getBal() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(msg.sender).transfer(amount);
        emit Transfer(address(this), msg.sender, amount);
    }

}