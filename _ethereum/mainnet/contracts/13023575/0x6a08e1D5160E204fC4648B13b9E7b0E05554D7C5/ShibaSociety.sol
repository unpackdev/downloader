pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";

contract ShibaSociety is ERC721("Shiba Society", "SHIBS"), Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    string baseURI1_;
    string baseURI2_;
    string blindURI1_;
    string blindURI2_;

    uint256 public totalSupply;
    uint256 public BUY_LIMIT_PER_TX = 10;
    uint256 public MAX_NFT = 10000;

    uint256 public constant NFTPrice = 68000000000000000; //0.068 ETH

    constructor() {}

    /*
     * Function to withdraw collected amount during minting
    */
    function withdraw(address _to) public onlyOwner {
        uint balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    /*
     * Function to mint new NFTs
     * It is payable. Amount is calculated as per (NFTPrice*_numOfTokens)
    */
    function mintNFT(uint256 _numOfTokens) public payable whenNotPaused {
        require(_numOfTokens <= BUY_LIMIT_PER_TX, "Can't mint above limit");
        require(totalSupply.add(_numOfTokens) <= MAX_NFT, "Purchase would exceed max supply of NFTs");
        require(NFTPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");

        for(uint i=0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply);
            totalSupply = totalSupply.add(1);
        }
    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (tokenId < 5000) {
            return bytes(baseURI1_).length > 0 && totalSupply >= MAX_NFT ? string(abi.encodePacked(baseURI1_, 
                tokenId.toString())) : string(abi.encodePacked(blindURI1_, tokenId.toString()));
        } else {
            return bytes(baseURI2_).length > 0 && totalSupply >= MAX_NFT ? string(abi.encodePacked(baseURI2_, 
                tokenId.toString())) : string(abi.encodePacked(blindURI2_, tokenId.toString()));
        }
    }

    /*
     * Function to set Base URI 
    */
    function setBaseURI(string memory _URI1, string memory _URI2) external onlyOwner {
        baseURI1_ = _URI1;
        baseURI2_ = _URI2;
    }

    /*
     * Function to set Blind URI 
    */
    function setBlindURI(string memory _URI1, string memory _URI2) external onlyOwner {
        blindURI1_ = _URI1;
        blindURI2_ = _URI2;
    }

    /*
     * Function to pause 
    */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * Function to unpause 
    */
    function unpause() external onlyOwner {
        _unpause();
    }
}