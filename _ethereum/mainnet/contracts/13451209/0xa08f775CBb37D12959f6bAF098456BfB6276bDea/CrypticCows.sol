// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract CrypticCows is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  address constant bigBucksAddress = 0x7118bAa246FC20451DEbf3E05B69591f8edad9ec;
  ERC721 constant bigBucks = ERC721(bigBucksAddress);

  address private melkAddress = address(0x0);

  uint256 constant price = 0.088 ether;
  uint256 private constant mintLimit = 50;
  uint256 private constant presaleMintLimit = 3;
  uint256 private constant supplyLimit = 3333;
  uint256 private constant totalMintLimit = supplyLimit - 888;
  bool private baseURISet = false;
  bytes32 whitelistMerkelRoot;

  address constant a1 = 0x7D0ab600c9CedefB7df3894Edc2e0114777F5d80;
  address constant a2 = 0x60DdBC16C4963D191439EF2f9297160250889aA0;

  // Sale Stages
  // 0 - Nothing enabled
  // 1 - Presale
  // 2 - Presale closed
  // 3 - Public sale
  // 4 - Big Bucks
  uint8 public saleStage = 0;
  uint256 public totalMinted = 0;
  string baseTokenURI;
  string unrevealedURI;

  string constant imageProvenance = "f1751775bc38f835e1942da8868a7046509ade8e23281087fb4e5d74b59ef132";

  mapping(uint256 => bool) private bigBucksUsed;
  mapping(address => uint256) private minted;
  mapping(uint256 => string) public customTokenURIs;

  constructor(string memory _unrevealedURI) ERC721("Cryptic Cows", "MOO") {
    unrevealedURI = _unrevealedURI;
    totalMinted += 10;

    for (uint256 i; i < 10; i++) {
      _safeMint(a1, i);
    }
  }

  function remainingMint(address user) public view returns (uint256) {
    return (saleStage < 2 ? presaleMintLimit : mintLimit) - minted[user];
  }

  function mint(uint256 num) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(saleStage > 2 || msg.sender == owner(), "Sale not started");
    require(remainingMint(msg.sender) >= num, "You can't mint any more cows");
    require(totalMinted + num < totalMintLimit, "Exceeds maximum supply");
    require(msg.value >= price * num, "Ether sent is not correct");

    minted[msg.sender] += num;
    totalMinted += num;

    for (uint256 i; i < num; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function claimWithBigBucks(uint256[] memory bigBucksIds) public nonReentrant {
    uint256 supply = totalSupply();
    require(saleStage > 3 || msg.sender == owner(), "Sale not started");

    minted[msg.sender] += bigBucksIds.length;

    for (uint256 i; i < bigBucksIds.length; i++) {
      require(bigBucks.ownerOf(bigBucksIds[i]) == msg.sender, "You don't own this Big Buck");
      require(!bigBucksUsed[bigBucksIds[i]], "This Big Buck has already been claimed");
      bigBucksUsed[bigBucksIds[i]] = true;
      _safeMint(msg.sender, supply + i);
    }
  }

  function whitelistMint(uint256 num, bytes32[] memory proof) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(saleStage == 1 || msg.sender == owner(), "Pre-sale not started or has ended");
    require(remainingMint(msg.sender) >= num, "You can't mint any more cows during the presale");
    require(totalMinted + num < totalMintLimit, "Exceeds maximum supply");
    require(msg.value >= num * price, "Ether sent is not correct");
    require(whitelistMerkelRoot != 0, "Whitelist not set");
    require(
      proof.verify(whitelistMerkelRoot, keccak256(abi.encodePacked(msg.sender))),
      "You aren't whitelisted"
    );

    minted[msg.sender] += num;
    totalMinted += num;

    for (uint256 i; i < num; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    require(!baseURISet, "Base URI must not already be set");

    baseTokenURI = baseURI;
    baseURISet = true;
  }

  function setCustomTokenURI(uint256 tokenId, string memory customTokenURI) public {
    require(msg.sender == melkAddress, "Only the $MELK contract can call this function");
    customTokenURIs[tokenId] = customTokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (bytes(customTokenURIs[tokenId]).length > 0) {
      return customTokenURIs[tokenId];
    }

    if (bytes(baseTokenURI).length > 0 && baseURISet) {
      return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    return unrevealedURI;
  }

  function isBigBuckUsed(uint256 tokenId) public view returns (bool) {
    return bigBucksUsed[tokenId];
  }

  function getPrice() public pure returns (uint256) {
    return price;
  }

  function setSaleStage(uint8 val) public onlyOwner {
    saleStage = val;
  }

  function setMelkAddress(address val) public onlyOwner {
    melkAddress = val;
  }

  function setWhitelistRoot(bytes32 val) public onlyOwner {
    whitelistMerkelRoot = val;
  }

  function withdrawAll() public onlyOwner {
    uint256 split = (2 * address(this).balance) / 5;
    uint256 res = address(this).balance - (split);

    payable(a1).transfer(res);
    payable(a2).transfer(split);
  }
}
