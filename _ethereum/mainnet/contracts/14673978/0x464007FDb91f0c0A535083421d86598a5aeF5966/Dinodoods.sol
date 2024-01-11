//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

interface IFossyl {
  function updateReward(address _from, address _to) external;
} 

contract DinoGenesis is ERC721Enumerable, Ownable {

  using Address for address;
  using SafeMath for uint256;

  IFossyl public Fossyl;

  bytes32 public presaleMerkleRoot;

  bool public saleActive;
  bool public presaleActive;
  string private baseURI;
  uint256 public maxSupply;
  uint256 public price;
  uint256 public maxPerWallet;

  mapping (address => bool) public presaleWhitelistClaimed;

  constructor() ERC721("DinoGenesis", "DINOGEN") { 
    maxPerWallet = 2;
    price = .065 ether;
    maxSupply = 375;
  }

  function mint(uint256 numberOfMints) public payable {
    require(saleActive,                                                   "Sale must be active to mint");
    require(numberOfMints > 0,                                            "Invalid purchase amount");
    require(balanceOf(msg.sender).add(numberOfMints) <= maxPerWallet,     "Invalid purchase amount");
    require(totalSupply().add(numberOfMints) <= maxSupply,                "Purchase would exceed max supply of Genesis Dinos");
    require(price.mul(numberOfMints) == msg.value,                        "Ether value sent is not correct");
    for(uint256 i; i < numberOfMints; i++) {
        _mint(msg.sender, totalSupply() + 1);
    }
  }

  function mintPresale(bytes32[] calldata _merkleProof) public payable {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf),     "Incorrect proof passed to validation");
    require(balanceOf(msg.sender).add(1) <= maxPerWallet,                  "Invalid purchase amount");
    require(!presaleWhitelistClaimed[msg.sender],                          "Owner has already minted reserved genesis Dino");
    require(presaleActive,                                                 "Presale must be active to mint");
    require(price == msg.value,                                            "Ether value sent is not correct");

    presaleWhitelistClaimed[msg.sender] = true;
    _mint(msg.sender, totalSupply() + 1);
  }

  function mintOwner(uint256 numberOfMints) public onlyOwner {
    require(totalSupply().add(numberOfMints) <= maxSupply,                "Purchase would exceed max supply of Genesis Dinos");
    for(uint256 i; i < numberOfMints; i++) {
        _mint(msg.sender, totalSupply() + 1);
    }
  }

  function walletOfOwner(address owner) public view returns(uint256[] memory) {
    uint256 tokenCount = balanceOf(owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for(uint256 i; i < tokenCount; i++){
        tokensId[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokensId;
  }
    
  function transferFrom(address from, address to, uint256 tokenId) public override {
    if (tokenId < maxSupply) {
      Fossyl.updateReward(from, to);
    }
    ERC721.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
    if (tokenId < maxSupply) {
        Fossyl.updateReward(from, to);
    }
    ERC721.safeTransferFrom(from, to, tokenId, data);
  }

  function setWhitelistRoot(bytes32 _root) external onlyOwner {
    presaleMerkleRoot = _root;
  }

  function setFossylAddress(address fossylAddress) external onlyOwner {
    Fossyl = IFossyl(fossylAddress);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function togglePresale() public onlyOwner {
    presaleActive = !presaleActive;
  }

  function toggleSale() public onlyOwner {
    saleActive = !saleActive;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }
  
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}