// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DogeGoblinTown is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant maxPublicMint = 10;
    uint256 public constant publicSalePrice = 0 ether;

    string private  baseTokenUri = "https://dogegoblintown.wtf/files/metadata/";

    bool public isPublicSaleActive = false;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("Doge Goblin Town", "DGT"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Doge Goblin Town :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "Doge Goblin Town :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Doge Goblin Town :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] + _quantity) <= maxPublicMint, "Doge Goblin Town :: Already minted!");
        require(msg.value >= (publicSalePrice * _quantity), "Doge Goblin Town :: Below ");
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721AMetadata: URI query for nonexistent token");
        uint256 trueId = tokenId + 1;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
