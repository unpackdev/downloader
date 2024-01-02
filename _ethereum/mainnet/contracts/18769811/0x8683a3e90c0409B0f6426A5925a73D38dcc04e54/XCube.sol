// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Ownable.sol";

/**
@title  XCube
@author Vitaly
*/
contract XCube is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 3333;
    uint256 public constant MINT_PRICE = 0.06 ether;
    uint public constant MAX_CUBES_PURCHASE = 15;

    uint256 private _currentTokenId = 0;

    mapping(uint256 => string) private _tokenURIs;

    string public baseTokenURI;

    bool public saleIsActive = false;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintCubes(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale not active");
        require(numberOfTokens <= MAX_CUBES_PURCHASE, "Exceeds max token purchase");
        require(totalSupply() + numberOfTokens <= TOTAL_SUPPLY, "Exceeds total supply");
        
        if (msg.sender != owner()) { // Check if the caller is not the owner
            require(MINT_PRICE * numberOfTokens == msg.value, "Ether value sent is incorrect");
        }

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ++_currentTokenId);
        }
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (uint256 tokenId = 1; tokenId <= _currentTokenId; tokenId++) {
                if (ownerOf(tokenId) == owner) {
                    result[index] = tokenId;
                    index++;
                }
            }
            return result;
        }
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function withdrawPayments(address payable payee) public onlyOwner {
        require(payee != address(0), "Cannot withdraw to zero address");
        (bool sent, ) = payee.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}
