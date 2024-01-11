// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Burn is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 888;
    uint256 public constant MAX_PUBLIC_MINT = 2;
    uint256 public constant PUBLIC_SALE_PRICE = 0 ether;

    string private  baseTokenUri;

    // deploy smart contract, set baseURI, team mint, toggleBorbSale 
    bool public isLive;
    bool public teamMinted;

    constructor() ERC721A("0EProgrammed", "ZERO") {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

      // Start tokenid at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(isLive, "Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require(_quantity <= MAX_PUBLIC_MINT, "Already minted 5 times!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Payment is below the price");

        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner {
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 50);
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, _toString(tokenId)/*, ".json"*/)) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function toggleSale() external onlyOwner {
        isLive = !isLive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function burnnnnnn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}