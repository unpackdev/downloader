// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract AkumuDragonz is ERC721A, Ownable {

  using Strings for uint256;
  string public        baseURI;
  uint256 public       price             = 0.169 ether;
  uint256 public       maxSupply         = 10000;
  uint256 public       maxPerWallet      = 4;
  bool public          mintEnabled       = false;
  bool public revealed = false;

  mapping(address => uint256) private _walletMints;
  bytes32 public merkleRoot = 0xf7114a142c8c071e09e1f238c6b8f267745aa3e12a752c8ce732d7d4725259d3;

  constructor() ERC721A("Akumu Dragonz", "AKUMU"){}

  function mint(uint256 amt) external payable {
    require(msg.value >= amt * price,"Please send the right amount.");
    require(totalSupply() + amt < maxSupply + 1, "Not enough Dragonz.");
    require(mintEnabled, "Minting is not live yet.");
    require(_walletMints[_msgSender()] + amt < maxPerWallet + 1, "Limit for this wallet reached");

    _walletMints[_msgSender()] += amt;
    _safeMint(msg.sender, amt);
  }

  function allowlistMint(uint256 amt, bytes32[] calldata merkleProof) external payable {
    require(totalSupply() + amt < maxSupply + 1, "Not enough Dragonz.");
    require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You're not on the Allowlist.");
    require(mintEnabled, "Minting is not live yet.");
    require(_walletMints[_msgSender()] + amt < maxPerWallet + 1, "Limit for this wallet reached");

    _walletMints[_msgSender()] += amt;
    _safeMint(msg.sender, amt);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!revealed) {
            return "https://www.akumudragonz.co/prereveal.json";
        }

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      merkleRoot = _merkleRoot;
  }

  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      maxPerWallet = maxPerWallet_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function withdrawAll() public onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0, "Insufficent balance");
      _withdraw(_msgSender(), address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Failed to withdraw Ether");
  }

}