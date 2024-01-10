// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract DojiEth is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_RESERVE = 100;
    uint256 public constant MAX_PUBLIC = 2012;
    uint256 public constant MAX_SUPPLY = MAX_RESERVE + MAX_PUBLIC;
    uint256 public constant UNIT_PRICE = 0 ether;
    uint256 public constant MAX_PER_MINT = 2;

    string private _tokenBaseURI = "https://doji.dev/api/metadata/";

    bool public reserveLive;
    bool public saleLive;
    bool public locked;

    event StoryTitle(uint256 indexed tokenId, string title);
    event StoryOfTheDay(uint256 indexed tokenId, string story);

    constructor() ERC721("Doji x Ethereum", "DOJIETH") {}

    modifier notLocked() {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function toggleReserveStatus() external onlyOwner {
        reserveLive = !reserveLive;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
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

    function mint(uint256 numberOfToken) public payable {
        require(saleLive, "SALE_CLOSED");
        if (reserveLive) {
            require(totalSupply() + numberOfToken <= MAX_SUPPLY, "SOLD_OUT");
        } else {
            require(totalSupply() + numberOfToken <= MAX_PUBLIC, "SOLD_OUT");
        }
        require(numberOfToken > 0, "CANNOT_MINT_NONE");
        if (msg.sender != owner()) {
            require(numberOfToken <= MAX_PER_MINT, "EXCEED_PER_MINT");
            require(balanceOf(msg.sender) < MAX_PER_MINT, "CANNOT_MINT_WITH_BALANCE");
        }

        for (uint256 i = 0; i < numberOfToken; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, toString(tokenId)));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setStoryTitle(uint256 tokenId, string memory _title) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this token");
        emit StoryTitle(tokenId, _title);
    }

    function setStory(uint256 tokenId, string memory _story) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this token");
        emit StoryOfTheDay(tokenId, _story);
    }
}
