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
    uint256 public maxWlMintAmount = 4;
    uint256 public laterTime = 2 minutes;
    uint256 public totalGift;
    bool public isWlSaleStart = false;
    uint256 public isWlSaleStartTime;
    bytes32 public wlMerkleRoot;
    bytes32 public freeMerkleRoot;

    mapping(address => uint256) public totalMint;
    mapping(address => uint256) public totalWlMint;
    mapping(address => bool) public isFreeMintAddress;

    constructor(string memory _secretUri) ERC721A("Chaotic 3D Mind", "Chaotic3DMind") {
        secretItemURI = _secretUri;
    }

    function whitelistMint(bytes32[] memory _wlMerkleProof, uint256 amount) public payable {
        require(isWlSaleStart, "Sale Has Not Started Yet");
        require(totalSupply() + amount <= 3333, "Maximum Total Suply");
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_wlMerkleProof, wlMerkleRoot, _leaf), "Not On The WhiteList");
        require(totalWlMint[msg.sender] + amount <= maxWlMintAmount, "Maximum Owned");
        require(msg.value >= amount * wlPrice, "Insufficient Balance");
        totalWlMint[msg.sender] += amount;
        totalMint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function saleMint(uint256 amount) public payable {
        require(isPublicSaleActive(), "Sale Has Not Started Yet");
        require(totalSupply() + amount <= 3333, "Maximum Total Suply");
        require(msg.value >= amount * standartPrice, "Insufficient Balance");
        require(totalMint[msg.sender] + amount <= 10, "Maximum Owned");
        totalMint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function freeMint(bytes32[] memory _freeMerkleProof) public {
        require(isPublicSaleActive(), "Sale Has Not Started Yet");
        require(totalSupply() + 1 <= 3333, "Maximum Total Suply");
        require(totalGift <= 332, "Fnished Free Mint");
        require(!isFreeMintAddress[msg.sender], "Already Done!");
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_freeMerkleProof, freeMerkleRoot, _leaf), "Not On The FreeList");
        isFreeMintAddress[msg.sender] = true;
        totalGift += 1;
        _safeMint(msg.sender, 1);
    }
    
    function sendGift(address _to, uint256 _amount) public onlyOwner{
        require(isWlSaleStart, "Sale Has Not Started Yet");
        require(totalSupply() + 1 <= 3333, "Maximum Total Suply");
        require(totalGift + _amount <= 333, "Fnished Free Mint");
         _safeMint(_to, _amount);
         totalGift += _amount;
    }

    function isPublicSaleActive() internal view returns(bool){
        bool statusPublicSale = isWlSaleStart && (isWlSaleStartTime + laterTime <= block.timestamp) ? true : false;
        return statusPublicSale;
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
        isWlSaleStartTime = block.timestamp;
        isWlSaleStart = !isWlSaleStart;
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

    function setMerkleRoot(bytes32 _WlmerkleRoot, bytes32 _FreemerkleRoot) external onlyOwner {
        wlMerkleRoot = _WlmerkleRoot;
        freeMerkleRoot = _FreemerkleRoot;
    }

    function setMaxWlMintAmount(uint256 _new) external onlyOwner{
        maxWlMintAmount = _new;
    }

    function setWlPrice(uint256 _newWlPrice) external onlyOwner {
        wlPrice = _newWlPrice;
    }

    function setLaterTime(uint256 _date) external onlyOwner{
        laterTime = _date;
    }

    function setStandartPrice(uint256 _newStandartPrice) external onlyOwner {
        standartPrice = _newStandartPrice;
    }

    function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

}