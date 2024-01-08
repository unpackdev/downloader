// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract TheSimpletons is Context, ERC721Enumerable, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;

  enum ClaimStatus { Unclaimed, Claimed }
  address private signerAddress;

  mapping (address => ClaimStatus) private presale;
  mapping(string => bool) private usedNonces;

  string private baseTokenURI;

  bool private isSaleActive = false;
  bool private isPreSaleActive = false;

  uint public mintPrice = 30000000000000000;
  uint public constant MAX_SUPPLY = 3000;
  uint public constant MAX_PER_TX = 10;
  uint[MAX_SUPPLY] private simpleton;
  uint private nonce = 0;

  constructor(string memory name, string memory symbol, string memory _baseTokenURI) ERC721(name, symbol) {
    baseTokenURI = _baseTokenURI;
  }

  function mint(address wallet, uint count, bytes32 hash, bytes memory signature, string memory _nonce) external payable nonReentrant() {
    require(isSaleActive == true && isPreSaleActive == false, "Check sale status");
    require(tx.origin == msg.sender, "Minting unauthorized");
    require(matchAddresSigner(hash, signature), "Wrong signature");
    require(!usedNonces[_nonce], "Hash used");
    require(hashTransaction(msg.sender, count, _nonce) == hash, "Hash failed");
    require(totalSupply() < MAX_SUPPLY, "No more mints");
    require(count > 0 && count <= MAX_PER_TX, "You can only mint 10 per tansaction");
    require(count <= MAX_SUPPLY - totalSupply(), "Not enough simpleton left to mint");
    require(msg.value >= count * mintPrice, "Value below price");

    _mintMultiple(wallet, count);
    usedNonces[_nonce] = true;
  }

  function mintPreSale(uint count, bytes32 hash, bytes memory signature, string memory _nonce) external payable nonReentrant() {
    require(isSaleActive == false && isPreSaleActive == true, "Check sale status");
    require(presale[msg.sender] == ClaimStatus.Unclaimed, "You are not able to claim again");
    require(presale[msg.sender] != ClaimStatus.Claimed, "You already claimed your presale tokens");
    require(tx.origin == msg.sender, "Minting unauthorized");
    require(matchAddresSigner(hash, signature), "Wrong signature");
    require(!usedNonces[_nonce], "Hash used");
    require(hashTransaction(msg.sender, count, _nonce) == hash, "Hash failed");
    require(totalSupply() < MAX_SUPPLY, "No more mints");
    require(count > 0 && count <= MAX_PER_TX, "You can only mint 10 per tansaction");
    require(count <= MAX_SUPPLY - totalSupply(), "Not enough simpleton left to mint");
    require(balanceOf(msg.sender) + count <= MAX_PER_TX, "Max presale is 10 Simpletons");
    require(msg.value >= count * mintPrice, "Value below price");

    _mintMultiple(msg.sender, count);
    usedNonces[_nonce] = true;

    if(balanceOf(msg.sender) == MAX_PER_TX) {
      presale[msg.sender] = ClaimStatus.Claimed;
    }
  }

  function hasSaleStarted() external view returns (bool) {
    return isSaleActive;
  }

  function hasPreSaleStarted() external view returns (bool) {
    return isPreSaleActive;
  }

  function getMintPrice() external view returns (uint) {
    return mintPrice;
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "This nft is not minted");

    return string(abi.encodePacked(baseTokenURI, uintToBytes(tokenId)));
  }

  function hashTransaction(address sender, uint256 count, string memory _nonce) private pure returns(bytes32) {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(sender, count, _nonce)))
    );
  }

  function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
    return signerAddress == hash.recover(signature);
  }

  function _mintMultiple(address wallet, uint count) private {
    uint i;
    uint id;

    for(i = 0; i < count; i++){
      id = randomIndex();
      _safeMint(wallet, id);
    }
  }

  function randomIndex() private returns (uint) {
    uint totalSize = MAX_SUPPLY - totalSupply();
    uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint value = 0;

    if (simpleton[index] != 0) {
      value = simpleton[index];
    } else {
      value = index;
    }

    if (simpleton[totalSize - 1] == 0) {
      simpleton[index] = totalSize - 1;
    } else {
      simpleton[index] = simpleton[totalSize - 1];
    }

    nonce++;
    return value + 1;
  }

  function mintPromo(address wallet, uint count) external onlyOwner {
    require(count <= MAX_SUPPLY - totalSupply(), "Not enough simpleton left to mint");

    _mintMultiple(wallet, count);
  }

  function setSignerAddress(address wallet) external onlyOwner {
    signerAddress = wallet;
  }

  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseTokenURI = _baseUri;
  }

  function toggleSale() external onlyOwner {
    isPreSaleActive = false;
    isSaleActive = !isSaleActive;
  }

  function togglePreSale() external onlyOwner {
    isSaleActive = false;
    isPreSaleActive = !isPreSaleActive;
  }

  function setMintPrice(uint _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function uintToBytes(uint v) private pure returns (bytes32 ret) {
    if (v == 0) {
      ret = '0';
    }
    else {
      while (v > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
        v /= 10;
      }
    }
    return ret;
  }
}
