// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Crocsgang is ERC721A, Ownable, ReentrancyGuard {

    uint public asdasd;
    mapping (address => uint256) public walletPublic;
    mapping (address => uint256) public walletWhitelist;
    string public baseURI;  
    bool public mintWhitelistEnabled = false;
    bool public mintPublicEnabled = false;
    bytes32 public merkleRoot;
    uint public freeNFT = 1;
    uint public maxPerTx = 5;  
    uint public maxPerWallet = 5;
    uint public maxSupply = 5555;
    uint public priceMint = 10000000000000000; //0.01 ETH

    constructor() ERC721A("Crocsgang", "Crocsgang",10,5555){}

    function whitelistMint(uint256 qty, bytes32[] calldata _merkleProof) external payable
    { 
        require(mintWhitelistEnabled, "Crocsgang: Minting Whitelist Pause");
        if(walletWhitelist[msg.sender] < freeNFT) 
        {
           uint256 claimFree = qty - freeNFT;
           require(msg.value >= claimFree * priceMint,"Crocsgang: Insufficient Eth Claim Free");
        }
        else
        {
           require(msg.value >= qty * priceMint,"Crocsgang: Insufficient Eth");
        }
        require(walletWhitelist[msg.sender] + qty <= maxPerWallet,"Crocsgang: Max Per Wallet");
        require(qty <= maxPerTx, "Crocsgang: Limit Per Transaction");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Crocsgang: Not in whitelisted");
        require(totalSupply() + qty <= maxSupply,"Crocsgang: We Are Soldout");
        walletWhitelist[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function publicMint(uint256 qty) external payable
    {
        require(mintPublicEnabled, "Crocsgang: Minting Public Pause");
        if(walletPublic[msg.sender] < freeNFT) 
        {
           uint256 claimFree = qty - freeNFT;
           require(msg.value >= claimFree * priceMint,"Crocsgang: Insufficient Eth Claim Free");
        }
        else
        {
           require(msg.value >= qty * priceMint,"Crocsgang: Insufficient Eth Normal");
        }
        require(walletPublic[msg.sender] + qty <= maxPerWallet,"Crocsgang: Max Per Wallet");
        require(qty <= maxPerTx, "Crocsgang: Limit Per Transaction");
        require(totalSupply() + qty <= maxSupply,"Crocsgang: We Are Soldout");
        walletPublic[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }
    
    function whitelistMint() public view returns (uint256) {
        return walletPublic[msg.sender];
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function airdrop(address to ,uint256 qty) external onlyOwner
    {
        _safeMint(to, qty);
    }

    function ownerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function togglePublicMinting() external onlyOwner {
        mintPublicEnabled = !mintPublicEnabled;
    }
    function toggleWhitelistMinting() external onlyOwner {
        mintWhitelistEnabled = !mintWhitelistEnabled;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        priceMint = price_;
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

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }
}