// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

interface FInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

contract Monkeys is ERC721, ERC721Enumerable, Ownable {
    uint256 public PROVENANCE;
    uint256 public MAX_TOKENS = 7000;
    bool public saleIsActive = false;

    address public fAddress = 0x772C9181b0596229cE5bA898772CE45188284379;
    FInterface fContract = FInterface(fAddress);

    string private _baseURILink;

    constructor() ERC721("Monkeys fo SFD", "MSFD") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI) external onlyOwner() {
        _baseURILink = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURILink;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function setProvenance(string memory rate) public onlyOwner {
        PROVENANCE = random(string(abi.encodePacked('SFDMonkeys', rate))) % 7000;
    }
    
    function directMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    
    function mintMany(uint32[] memory ids) public {
        require(saleIsActive, "Sale must be active to mint tokens");
        require(fContract.balanceOf(msg.sender) > 0, "Must own an Frog to mint token");
        
        for (uint i = 0; i < ids.length; i++) {
            require(fContract.ownerOf(ids[i]) == msg.sender, "Must own an Frog to mint token");
            _safeMint(msg.sender, ids[i]);
        }
    }
    
    function mintToken(uint tokenId) public {
        require(saleIsActive, "Sale must be active to mint tokens");
        require(fContract.balanceOf(msg.sender) > 0, "Must own an Frog to mint token");
        require(fContract.ownerOf(tokenId) == msg.sender, "Must own an Frog to mint token");

        _safeMint(msg.sender, tokenId);
    }
}