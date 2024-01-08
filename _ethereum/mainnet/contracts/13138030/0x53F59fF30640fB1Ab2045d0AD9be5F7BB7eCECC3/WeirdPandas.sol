pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";

contract WeirdPandas is ERC721, ERC721URIStorage, Pausable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string private _baseURIextended;
    
    uint256 public totalSupply = 0;
    uint256 public buyLimit = 10;
    uint256 public maxSupply = 2777;
    uint256 public nftPrice = 70000000000000000;

    constructor() ERC721 ("WeirdPandas", "WPNFT") {
        _safeMint(msg.sender, totalSupply);
        _setTokenURI(totalSupply, totalSupply.toString());
        totalSupply = totalSupply.add(1);
    }
    
    function withdraw(address _to) public onlyOwner {
        uint balance = address(this).balance;
        payable(_to).transfer(balance);
    }
    
    function setPrice(uint value) public onlyOwner {
        nftPrice = value;
    }
    
    function setMax(uint value) public onlyOwner {
        maxSupply = value;
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    function _setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage){
        require(_isApprovedOrOwner(msg.sender, tokenId), "You are not the owner nor approved!");
        super._burn(tokenId);
    }
    
    function mintNFT(uint256 _numOfTokens) public payable whenNotPaused {
        require(_numOfTokens <= buyLimit, "Can't mint above limit");
        require(totalSupply.add(_numOfTokens) <= maxSupply, "Purchase would exceed max supply of NFTs");
        require(nftPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");
        
        for(uint i=0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply);
            _setTokenURI(totalSupply, totalSupply.toString());
            totalSupply = totalSupply.add(1);
        }
    }
}