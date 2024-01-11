// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Abokado is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = true;
    string private baseURI;
    address payable public immutable beneficiaryAddress;
    uint256 constant MAX_SUPPLY = 3000;
    uint256 public price = 0.02 ether;

    constructor(address payable _beneficiaryAddress, string memory baseURI_, string memory provenance) ERC721("Abokado", "ABOKADO") {
        require(_beneficiaryAddress != address(0));
        beneficiaryAddress = _beneficiaryAddress;
        baseURI = baseURI_;
        PROVENANCE = provenance;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= 10, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(price * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint ts = totalSupply();
            if (ts < MAX_SUPPLY) {
                _safeMint(msg.sender, ts + 1);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(beneficiaryAddress, balance);
    }
}