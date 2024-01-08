// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";

contract DogePirates is ERC721("DOGE Pirates", "DOPE"), ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    string[7] private baseURI;
    string private blindURI;

    uint256 public BUY_LIMIT_PER_TX = 20;
    uint256 public MAX_NFT = 3333;
    uint256 public NFTPrice = 42000000000000000;  // 0.042 ETH

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
        require(totalSupply().add(_numOfTokens) <= MAX_NFT, "Purchase would exceed max supply of NFTs");
        require(NFTPrice.mul(_numOfTokens) == msg.value, "Ether value sent is not correct");

        for(uint i=0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    /*
     * Function to get token URI of given token ID
     * URI will be blank untill totalSupply reaches MAX_NFT
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (tokenId < 333) {
            return bytes(baseURI[0]).length > 0 && totalSupply() >= 333 ? string(abi.encodePacked(baseURI[0], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        } else if (tokenId >= 333 && tokenId < 888) {
            return bytes(baseURI[1]).length > 0 && totalSupply() >= 888 ? string(abi.encodePacked(baseURI[1], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        } else if (tokenId >= 888 && tokenId < 1337) {
            return bytes(baseURI[2]).length > 0 && totalSupply() >= 1337 ? string(abi.encodePacked(baseURI[2], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        } else if (tokenId >= 1337 && tokenId < 1888) {
            return bytes(baseURI[3]).length > 0 && totalSupply() >= 1888 ? string(abi.encodePacked(baseURI[3], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        } else if (tokenId >= 1888 && tokenId < 2333) {
            return bytes(baseURI[4]).length > 0 && totalSupply() >= 2333 ? string(abi.encodePacked(baseURI[4], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        } else if (tokenId >= 2333 && tokenId < 2888) {
            return bytes(baseURI[5]).length > 0 && totalSupply() >= 2888 ? string(abi.encodePacked(baseURI[5], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        } else {
            return bytes(baseURI[6]).length > 0 && totalSupply() >= MAX_NFT ? string(abi.encodePacked(baseURI[6], 
                tokenId.toString())) : string(abi.encodePacked(blindURI, tokenId.toString()));
        }
    }

    /*
     * Function to set Base and Blind URI 
    */
    function setURIs(string memory _blindURI, string[7] memory _URIs) external onlyOwner {
        require(_URIs.length == 7, "7 URI required");
        blindURI = _blindURI;
        baseURI = _URIs;
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

    // Standard functions to be overridden 
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, 
    ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}