// contracts/DoodlesZoo.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DoodlesZoo is ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public price = 0.04 ether;
    uint256 public max_supply = 3500;
    uint256 public max_quantity = 5;
    bool public live = false;
    uint256 public whitelist_price = 0.02 ether;
    uint256 public whitelist_max_quantity = 2;
    bool public whitelist_live = false;
    mapping(address => uint256) private whitelist_claims;
    string private _baseUri;
    bytes32 private _merkleRoot;

    constructor() ERC721("DoodlesZoo", "DZ") public {
    }

    function mint(uint256 quantity) external payable {
        require(live, "Public sale paused");
        require(msg.value == price * quantity, "Invalid ether amount");
        require(quantity > 0 && quantity <= max_quantity, "Invalid quantity");
        require(totalSupply() + quantity <= max_supply, "Sold out");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 quantity) external payable {
        require(whitelist_live, "Whitelist mint paused");
        require(msg.value == whitelist_price * quantity, "Invalid ether amount");
        require(quantity > 0 && quantity <= whitelist_max_quantity, "Invalid quantity");
        require(totalSupply() + quantity <= max_supply, "Sold out");
        require(whitelist_claims[msg.sender] + quantity <= whitelist_max_quantity, "Already minted");
        require(MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            whitelist_claims[msg.sender]++;
            _safeMint(msg.sender, tokenId);
        }
    }

    function togglePublicSale() external onlyOwner {
        live = !live;
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelist_live = !whitelist_live;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function gift(address _address, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= max_supply, "Sold out");
        require(_address != address(0), "Invalid address");
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(_address, tokenId);
        }
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelistPrice(uint256 _price) external onlyOwner {
        whitelist_price = _price;
    }

    function setPublicMaxQuantity(uint256 _quantity) external onlyOwner {
        max_quantity = _quantity;
    }

    function setWhitelistMaxQuantity(uint256 _quantity) external onlyOwner {
        whitelist_max_quantity = _quantity;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        max_supply = _supply;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        _baseUri = uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
    }
}
