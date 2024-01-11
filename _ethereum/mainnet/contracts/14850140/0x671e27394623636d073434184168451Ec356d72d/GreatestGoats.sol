// SPDX-License-Identifier: MIT

// @Author Manuel (ManuelH#0001)

pragma solidity ^ 0.8 .9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract GreatestGoats is ERC721A, Ownable {
    using Strings for uint256;

    bytes32 public holderSaleMerkleRoot = 0x690accb73629b79fec6e254e188c7005d885276e4360c9b0cfceb3f92e0a85a8;
    uint256 private constant maxSupply = 4444;

    string public BaseURI = "ipfs://QmXszTJoGN6dA6KyCz1X33wxdGydvxWoopBDdxExgBvmDj/";

    uint8 public isMaxHolderSaleMints = 2;
    uint8 public isMaxPublicSaleMints = 1;

    mapping(address => uint256) public hasHolderMinted;
    mapping(address => uint256) public hasPublicMinted;

    bool isHoldersSaleActive = false;
    bool isPublicSaleActive = false;

    constructor() ERC721A("GreatestGoats", "GG"){}

    function holderMint(uint256 _quantity, bytes32[] calldata proof) external payable {
        require(isHoldersSaleActive, "Holder sale has yet to be activated or already has been activated and is over.");
        require(msg.value == 0 * _quantity, "You're sending too much ETH");
        require(hasHolderMinted[msg.sender] + _quantity <= isMaxHolderSaleMints, "You reached you're max mints");
        require(totalSupply() + _quantity <= maxSupply, "The supply cap is reached.");
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool isValidProof = MerkleProof.verify(proof, holderSaleMerkleRoot, sender);
        require(isValidProof, "Invalid proof");
        hasHolderMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable {
        require(isPublicSaleActive, "Public sale has yet to be activated or already has been activated and is over.");
        require(msg.value == 0 * _quantity, "You're sending too much ETH");
        require(hasPublicMinted[msg.sender] + _quantity <= isMaxPublicSaleMints, "You reached you're max mints");
        require(totalSupply() + _quantity <= maxSupply, "The supply cap is reached.");
        hasPublicMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(BaseURI, _tokenId.toString(), ".json"));
    }

    function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
        return 1;
    }
    
    function setHolderSaleDetails(bytes32 _root, uint8 _maxMint) external onlyOwner {
      holderSaleMerkleRoot = _root;
      isMaxHolderSaleMints = _maxMint;
    }

    function setPublicSaleDetails(uint8 _maxMint) external onlyOwner {
        isMaxPublicSaleMints = _maxMint;
    }
    function toggleHolderSaleActive() external onlyOwner {
        isHoldersSaleActive = !isHoldersSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }
}