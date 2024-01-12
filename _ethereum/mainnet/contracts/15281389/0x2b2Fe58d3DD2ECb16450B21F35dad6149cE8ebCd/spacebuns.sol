// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// ░██████╗██████╗░░█████╗░░█████╗░███████╗  ██████╗░██╗░░░██╗███╗░░██╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝  ██╔══██╗██║░░░██║████╗░██║██╔════╝
// ╚█████╗░██████╔╝███████║██║░░╚═╝█████╗░░  ██████╦╝██║░░░██║██╔██╗██║╚█████╗░
// ░╚═══██╗██╔═══╝░██╔══██║██║░░██╗██╔══╝░░  ██╔══██╗██║░░░██║██║╚████║░╚═══██╗
// ██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗  ██████╦╝╚██████╔╝██║░╚███║██████╔╝
// ╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝  ╚═════╝░░╚═════╝░╚═╝░░╚══╝╚═════╝░

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";
import "./IERC721Enumerable.sol";

contract SpaceBuns is ERC721A, ReentrancyGuard, Ownable {
    IERC721Enumerable public immutable billionBuns;

    bytes32 public alMerkleRoot;
    bytes32 public ogMerkleRoot;
    bytes32 public reserveMerkleRoot;

    string public baseURI;
    string public revealURI;

    uint256 public mintPrice = 0.099 ether;
    uint256 public alMintPrice = 0.077 ether;
    uint256 public maxSupply;
    uint256 public reserveSupply;
    uint256 public reserveCounter;

    uint256 public maxOGMint;

    bool public isPublicMint;
    bool public isAlMint;
    bool public isReserveMint;
    bool public revealed = false;

    mapping(address => uint256) private _ogWallets;
    mapping(address => uint256) private _reserveWallets;

    constructor() payable ERC721A("SPACEBUNS", "BB") {
      maxSupply = 3600;
      reserveSupply = 600;
      reserveCounter = 600;

      maxOGMint = 1;

      billionBuns = IERC721Enumerable(0xc7c4dE92aA4dFcfC4e3cb82a351c4cA1AF33D373);
    }

    function _priceCalc(uint _quantity) private view {
      require(_quantity > 0, "You need to mint at least 1 NFT.");
      if (isAlMint) {
        require(msg.value >= alMintPrice * _quantity, "Insufficient ETH");
      } else {
        require(msg.value >= mintPrice * _quantity, "Insufficient ETH");
      }
      require(maxSupply - reserveCounter >= totalSupply() + _quantity, "Sold out or Exceeds max tokens");
    }

    modifier priceCalc(uint _quantity) {
      _priceCalc(_quantity);
      _;
    }

    // Minting - public, allow list, marketing mint, reserve mint
    function publicMint(uint256 _quantity) external payable nonReentrant priceCalc(_quantity) {
      require(isPublicMint, "Public minting is not live.");
      _safeMint(msg.sender, _quantity);
    }

    function alMint(bytes32[] calldata _merkleProof, uint256 _quantity) external payable nonReentrant priceCalc(_quantity) {
      require(isAlMint, "Minting is not live.");
      require(MerkleProof.verify(_merkleProof, alMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on the allow list.");
      _safeMint(msg.sender, _quantity);
    }

    function ogMint(bytes32[] calldata _merkleProof) external nonReentrant {
      require(isAlMint || isPublicMint, "Minting is not live.");
      require(MerkleProof.verify(_merkleProof, ogMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on the OG List.");
      require(billionBuns.balanceOf(msg.sender) > 0, "You do not own a Billion Buns NFT");
      require(_ogWallets[msg.sender] + 1 <= maxOGMint, "You reached max per wallet.");
      require(maxSupply >= totalSupply() + 1, "Sold out or Exceeds max tokens");
      require(reserveCounter > 0, "Reserve mint is complete.");

      _ogWallets[msg.sender]++;
      reserveCounter--;
      _safeMint(msg.sender, 1);
    }

    function reserveMint(bytes32[] calldata _merkleProof, uint256 _quantity) external nonReentrant {
      require(isReserveMint, "Minting is not live.");
      require(MerkleProof.verify(_merkleProof, reserveMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on the reserve list.");
      require(_quantity > 0, "You need to mint at least 1 NFT.");
      require(maxSupply >= totalSupply() + _quantity, "Sold out or Exceeds max tokens");
      require(reserveCounter > 0, "Reserve mint is complete.");

      for (uint256 i = 0; i < _quantity; i++) {
        _reserveWallets[msg.sender]++;
        reserveCounter--;
      }

      _safeMint(msg.sender, _quantity);
    }

    function ogMintStatus(bytes32[] calldata _merkleProof) public view returns (bool) {
      require(MerkleProof.verify(_merkleProof, ogMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Address is not on the OG List.");
      return billionBuns.balanceOf(msg.sender) > 0 && _ogWallets[msg.sender] == 0 ? true : false;
    }

    function getClaimIneligibilityReason(address _userWallet, uint256 _quantity) public view returns (string memory) {
      require(maxSupply - reserveCounter >= totalSupply() + _quantity, "Exceeds max tokens");
      return "";
    }

    function unclaimedSupply() public view returns (uint256) {
      return maxSupply - reserveCounter - totalSupply() + reserveCounter;
    }

    function price() public view returns (uint256) {
      return isPublicMint ? mintPrice : alMintPrice;
    }

    function claimTo(address _userWallet, uint256 _quantity) public payable nonReentrant priceCalc(_quantity) {
      require(isAlMint || isPublicMint, "Minting is not live.");
      _safeMint(_userWallet, _quantity);
    }

    // onlyOwner -- set merkle root
    function setMerkleRoot(bytes32 _alMerkleRoot, bytes32 _ogMerkleRoot, bytes32 _reserveMerkleRoot) external onlyOwner {
      alMerkleRoot = _alMerkleRoot;
      ogMerkleRoot = _ogMerkleRoot;
      reserveMerkleRoot = _reserveMerkleRoot;
    }

    // onlyOwner Token / Reveal URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721A Metadata: URI query for nonexistent token");
      if (revealed == false) {
        return revealURI;
      }
      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function setBaseURI(string memory _newBaseURI, string memory _revealURI) external onlyOwner() {
      baseURI = _newBaseURI;
      revealURI = _revealURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    // onlyOwner Admin functions

    function reveal() external onlyOwner {
      revealed = !revealed;
    }

    function toggleMintStatus(bool _public, bool _allow, bool _reserve) external onlyOwner() {
      isPublicMint = _public;
      isAlMint = _allow;
      isReserveMint = _reserve;
    }

    function setSupply(uint256 _maxSupply, uint256 _reserve) external onlyOwner() {
      maxSupply = _maxSupply;
      reserveSupply = _reserve;
      reserveCounter = _reserve;
    }

    // onlyOwner - withdrawl

    function withdrawSplit() external nonReentrant onlyOwner {
      uint256 balance = address(this).balance;
      (bool wallet1, ) = payable(0x42a9ACf4a15245Fac00B3cA89A4AC9032a94A660).call{value: balance * 25 / 100}("");
      (bool wallet2, ) = payable(0xD5a1a7E5a2Eb6bFeeEB1cb26851b27dd0e50d510).call{value: address(this).balance}("");
      require(wallet1, "Withdraw 1 failed");
      require(wallet2, "Withdraw 2 failed");
    }

    function withdraw() public nonReentrant onlyOwner {
      (bool wallet1, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(wallet1, "Withdraw 1 failed");
    }
}