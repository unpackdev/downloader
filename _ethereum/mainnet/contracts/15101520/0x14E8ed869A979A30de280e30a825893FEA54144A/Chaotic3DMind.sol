// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Chaotic3DMind is Ownable, ERC721A {
    using Strings for uint256;

    string public baseURI;
    string secretItemURI;
    bool public revealed = false;
    uint256 private constant MAX_SUPPLY = 3333;
    uint256 public wlPrice = 0.06 ether;
    uint256 public standartPrice = 0.08 ether;
    uint256 public totalGift;
    bool public isSaleStart = false;
    bytes32 public wlMerkleRoot;
    bytes32 public freeMerkleRoot;

    mapping(address => uint256) public maxMintAmount;
    mapping(address => bool) public freeMintAddress;

    constructor(string memory _secretUri) ERC721A("Chaotic 3D Mind", "Chaotic3DMind") {
        secretItemURI = _secretUri;
    }

    function whitelistMint(bytes32[] memory _wlMerkleProof, uint256 amount) public payable {
        require(isSaleStart, "Sale Has Not Started Yet");
        require(totalSupply() + amount <= 3333, "Maximum Total Suply");
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_wlMerkleProof, wlMerkleRoot, _leaf), "Not On The WhiteList");
        require(maxMintAmount[msg.sender] + amount <= 10, "Maximum Owned");
        require(msg.value >= amount * wlPrice, "Insufficient Balance");
        maxMintAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function saleMint(uint256 amount) public payable {
        require(isSaleStart, "Sale Has Not Started Yet");
        require(totalSupply() + amount <= 3333, "Maximum Total Suply");
        require(msg.value >= amount * standartPrice, "Insufficient Balance");
        require(maxMintAmount[msg.sender] + amount <= 10, "Maximum Owned");
        maxMintAmount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function freeMint(bytes32[] memory _freeMerkleProof) public {
        require(isSaleStart, "Sale Has Not Started Yet");
        require(totalSupply() + 1 <= 3333, "Maximum Total Suply");
        require(totalGift <= 332, "Fnished Free Mint");
        require(!freeMintAddress[msg.sender], "Already Done!");
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_freeMerkleProof, freeMerkleRoot, _leaf), "Not On The FreeList");
        freeMintAddress[msg.sender] = true;
        totalGift += 1;
        _safeMint(msg.sender, 1);
    }
    
    function sendGift(address _to) public onlyOwner{
        require(isSaleStart, "Sale Has Not Started Yet");
        require(totalSupply() + 1 <= 3333, "Maximum Total Suply");
        require(totalGift <= 332, "Fnished Free Mint");
        require(!freeMintAddress[msg.sender], "Already Done!");
         _safeMint(_to, 1);
          freeMintAddress[_to] = true;
         totalGift += 1;
    }

    function setSecretItemURI(string memory _newSecretItemURI) external onlyOwner {
        secretItemURI = _newSecretItemURI;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function changeBaseURIVisibility() public onlyOwner {
        revealed = !revealed;
    }
    function changeSaleStatus() public onlyOwner {
        isSaleStart = !isSaleStart;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (!revealed) {
            return secretItemURI;
        }
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setWlMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        wlMerkleRoot = _merkleRoot;
    }
    
    function setfreeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        freeMerkleRoot = _merkleRoot;
    }

    function setWlPrice(uint256 _newWlPrice) external onlyOwner {
        wlPrice = _newWlPrice;
    }
    function setStandartPrice(uint256 _newStandartPrice) external onlyOwner {
        standartPrice = _newStandartPrice;
    }

     function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

}