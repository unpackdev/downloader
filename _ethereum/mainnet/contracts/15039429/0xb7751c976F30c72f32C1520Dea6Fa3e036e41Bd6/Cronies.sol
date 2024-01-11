// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Cronies is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;  
    uint public priceWhitelist = 10000000000000000; //0.01 ETH
    uint public pricePublic = 15000000000000000; //0.015 ETH
    uint public maxPerTx = 5;  
    uint public maxPerWallet = 5;
    uint public maxSupply = 5555;
    bool public mintEnabled = false;
    bytes32 public merkleRoot;
    mapping (address => uint256) public addressPublic;
    mapping (address => uint256) public addressWhitelist;

    constructor() ERC721A("Cronies", "Cronies"){}

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function airdrop(address to ,uint256 amount) external onlyOwner
    {
        _safeMint(to, amount);
    }

    function ownerBatchMint(uint256 amount) external onlyOwner
    {
        _safeMint(msg.sender, amount);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPricePublic(uint256 price_) external onlyOwner {
        pricePublic = price_;
    }

    function setPriceWhitelist(uint256 price_) external onlyOwner {
        priceWhitelist = price_;
    } 

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function whitelistMint(uint256 amount, bytes32[] calldata _merkleProof) external payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(mintEnabled, "Cronies: Minting Pause");
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Cronies: You are not whitelisted");
        require(msg.value <= amount * priceWhitelist,"Cronies: Insufficient Funds");
        require(totalSupply() + amount <= maxSupply,"Cronies: Soldout");
        require(addressWhitelist[msg.sender] + amount <= maxPerWallet,"Cronies: Max Per Wallet");
        require(amount <= maxPerTx, "Cronies: Limit Per Transaction");
        addressWhitelist[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) external payable
    {
        require(mintEnabled, "Cronies: Minting Pause");
        require(msg.value <= amount * pricePublic,"Cronies: Insufficient Funds");
        require(totalSupply() + amount <= maxSupply,"Cronies: Soldout");
        require(addressPublic[msg.sender] + amount <= maxPerWallet,"Cronies: Max Per Wallet");
        require(amount <= maxPerTx, "Cronies: Limit Per Transaction");
        addressPublic[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }
}