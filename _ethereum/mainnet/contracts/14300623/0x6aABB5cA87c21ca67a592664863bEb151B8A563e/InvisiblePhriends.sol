// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";


contract InvisiblePhriends is ERC721, ERC721Enumerable {

    bool public saleIsActive = false;
    string public _baseUri = "ipfs://QmbzHGJDKVZ22TE6VsixdmMPgbR5QamCfpuKV8jF826NVe/";
    uint public _mint = 0.0069 ether;
    address public owner;

    constructor() ERC721("InvisiblePhriends", "IPH") {
        owner = msg.sender;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Not the owner!");
        _;
    }

    function transferOwnership (address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function _baseURI() internal view override returns(string memory) {
        return _baseUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory json = string(
                    abi.encodePacked(
                        _baseUri,
                        '/',
                        Strings.toString(_tokenId),
                        '.json'
                    )
                );
        return json;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mintPrice(uint8 newMint) public onlyOwner {
        _mint = newMint;
    }

    function mintTokens(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= 20, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= 5000, "Sold out");

        if(totalSupply() + numberOfTokens > 1000){
            require(_mint * numberOfTokens == msg.value, "Ether value sent is not correct");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() <= 5000) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}