// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract arcticfoxpups is ERC721A, ReentrancyGuard, Ownable {
    uint256 MAX_MINTS = 20;
    uint8 public MAX_OG_MINTS = 10;
    uint8 public MAX_FREE_MINTS = 1;

    uint16 MAX_SUPPLY = 6666;
    uint256 public ogMintRate = 0.003 ether;
    uint256 public mintRate = 0.005 ether;
    
    bytes32 ogMerkleRoot;

    bool public ogMintEnabled = false;
    bool public publicMintEnabled = false;
    
    string baseURI = "ipfs://QmdjacToQ2ZzaRgTE6b4LAVTiA1aArUp2ScmbHMyqz243k/";

    constructor(bytes32 _ogMerkleRoot) ERC721A("Arctic Fox Pups", "AFPs") {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function ogMint(uint8 quantity, bytes32[] memory proof) external payable nonReentrant{
        uint256 balance = _numberMinted(msg.sender);
        require(ogMintEnabled, "Unabel to mint at the moment");
        bool isOg = isValidOg(proof, keccak256(abi.encodePacked(msg.sender)));
        require(isOg, "Public mint is not open yet");
        require(quantity > 0, "Invalid quantity");
        require(quantity + balance <= MAX_OG_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        
        if(balance == 0){
            require(msg.value >= (quantity - MAX_FREE_MINTS) * ogMintRate, "Not enough ether sent");
        } else{
            require(msg.value >= (quantity) * ogMintRate, "Not enough ether sent");
        }
        _safeMint(msg.sender, quantity);
    }
    
    function mint(uint8 quantity) external payable nonReentrant{
        require(quantity > 0, "Invalid quantity");
        uint256 balance = _numberMinted(msg.sender);
        require(publicMintEnabled, "Unabel to mint at the moment");
        require(quantity + balance <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (quantity * mintRate), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setOgMintRate(uint256 _mintRate) public onlyOwner {
        ogMintRate = _mintRate;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner{
        mintRate = _mintRate;
    }

    function setBaseUri(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function setOgMintEnabled(bool _ogMintEnabled) public onlyOwner{
        ogMintEnabled = _ogMintEnabled;
    }

    function setPublicMintEnabled(bool _publicMintEnabled) public onlyOwner{
        publicMintEnabled = _publicMintEnabled;
    }

    function _startTokenId() internal pure override returns (uint) {
        return 1;
    }

    function setOgMerkleRoot(bytes32 _ogMerkleRoot) public onlyOwner{
        ogMerkleRoot = _ogMerkleRoot;
    }

    function isValidOg(bytes32[] memory proof, bytes32 leaf) internal view returns (bool){
        return MerkleProof.verify(proof, ogMerkleRoot, leaf);
    }
}