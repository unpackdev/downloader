// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721URIStorage.sol";

contract DMNSN is ERC721, Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private _tokenIds;
    bool isMintingActive = false;

    
    constructor() ERC721("DMNSN", "DMNSN") {}

    function activateMinting() public onlyOwner {
        isMintingActive = true;
    }

    function deactivateMinting() public onlyOwner {
        isMintingActive = false;
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


    function mint(string memory _uri, uint256 _price) public payable returns (uint256) {
        require(isMintingActive, "Minting on the DMNSN platform is not active.");
        require(msg.value >= _price, "Amount of ether sent not enough");
        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _uri);
        _tokenIds.increment();
        return tokenId;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}