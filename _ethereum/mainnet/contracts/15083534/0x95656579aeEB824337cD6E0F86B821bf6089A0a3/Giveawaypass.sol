//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";

contract NFTCollectible is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 1000;
    uint public constant PRICE = 0.03 ether;
    uint public constant MAX_PER_MINT = 3;
        
    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("Giveaway Pass", "GWP") {
        setBaseURI(baseURI);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal 
                    view 
                    virtual 
                    override 
                    returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mintNFTs(uint _count) public payable whenNotPaused {
        uint totalMinted = _tokenIds.current();
        require(
        totalMinted.add(_count) <= MAX_SUPPLY, "Not enough NFTs!"
        );
        require(
        _count > 0 && _count <= MAX_PER_MINT, 
        "Cannot mint specified number of NFTs."
        );
        require(
        msg.value >= PRICE.mul(_count), 
        "Not enough ether to purchase NFTs."
        );
        for (uint i = 0; i < _count; i++) {
                _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
      uint newTokenID = _tokenIds.current();
      _safeMint(msg.sender, newTokenID);
      _tokenIds.increment();
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }   
}