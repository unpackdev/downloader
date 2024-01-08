//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./BitMaps.sol";
import "./Strings.sol";
import "./MerkleProof.sol";


contract Pinazza is Ownable, ERC721Enumerable, ERC721Burnable, ERC721URIStorage  {

  using BitMaps for BitMaps.BitMap;
  using Strings for uint256;

  uint256 public SUPPLY_FOR_SALE;
  uint256 public price;
  bytes32 public merkleRoot;
  bool public salePaused;
  string private _baseTokenExtension;    
  mapping (address => bool) public claimed;

  string private _baseTokenURI;

  constructor(uint256 supplyToSell, uint256 initialPrice, string memory baseURI) ERC721("Pinazza", "PNZ") {
    salePaused = true;
    SUPPLY_FOR_SALE = supplyToSell;
    price = initialPrice;
    _baseTokenExtension = '';
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  /************ OWNER FUNCTIONS ************/

  function changeBaseURI(string calldata baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setMerkleRoot(bytes32 root) public onlyOwner {
    merkleRoot = root;
  }
  
  function collect() public onlyOwner {
        uint remainder = address(this).balance;
        uint split = remainder / 3;
        payable(0x78160a087f0714Aa6D342760eF9A132AfeC42476).transfer(split);
        payable(0x42128A2f460FC79129B986bb9195a5D5D61D9184).transfer(split);
        payable(0x4cCEC5C60607ab287a6F3bD0d581BfFe6f307779).transfer(address(this).balance);
  }
  
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function beginSale() public onlyOwner {
    salePaused = false;
  }

  function pauseSale() public onlyOwner {
    salePaused = true;
  }

  function ownerMint(uint256 quantity, address to) public onlyOwner {
    require(totalSupply() + quantity <= SUPPLY_FOR_SALE, "MINT:SOLD OUT");
    for(uint i = 0; i < quantity; i++) {
      _mint(to, totalSupply());
    }
  }
  
  function setTokenExtension(string memory extension) public onlyOwner {
    _baseTokenExtension = extension;
  }

  /************ PUBLIC FUNCTIONS ************/

  function mint(uint256 quantity) public payable {
    require(totalSupply() + quantity <= SUPPLY_FOR_SALE, "MINT:SOLD OUT");
    require(msg.value == price * quantity, "MINT:MSG.VALUE INCORRECT");
    require(!salePaused, "MINT:SALE PAUSED");
    for (uint256 i = 0; i < quantity; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  function claim(bytes32[] calldata proof, uint amount) public {
    require(!claimed[msg.sender], "CLAIM:ALREADY CLAIMED");
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, amount))), "CLAIM:INVALID PROOF");
    claimed[msg.sender] = true;
    for(uint i = 0; i < amount; i++) {
      _mint(msg.sender, totalSupply());
    }
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return string(abi.encodePacked(_baseURI(), tokenId.toString(), _baseTokenExtension));
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }
}
