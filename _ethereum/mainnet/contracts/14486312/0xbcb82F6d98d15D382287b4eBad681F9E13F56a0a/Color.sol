// SPDX-License-Identifier: MIT
// Website: https://color.sale
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract Color is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string  private baseURIextended;
    uint256 private MAX_MINT        = 50;
    uint256 public  PRICE           = 0.006 ether;
    uint256 public  MAX_SUPPLY      = 16777216;
    address private mainAddress;

    constructor(string memory _baseURI) ERC721 ("Color", "CLR") {
        mainAddress = msg.sender;
        baseURIextended = _baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURIextended = newBaseURI;
    }

    function baseURI() public view returns (string memory) {
        return baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = baseURI();
        string memory _tokenURI = tokenId.toString();

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function setAddress(address _mAddress) public onlyOwner {
        mainAddress = _mAddress;
    }
    
    function mint(uint numberOfTokens) public payable callerIsUser {
        uint256 supply = totalSupply();
        uint256 ownerSupply = balanceOf(msg.sender);

        require(numberOfTokens <= MAX_MINT, "Exceeded max token purchase");
        require(ownerSupply + numberOfTokens <= MAX_MINT, "You exceed the maximum amount per wallet");
        require(supply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(mainAddress).transfer(balance);
    }
}