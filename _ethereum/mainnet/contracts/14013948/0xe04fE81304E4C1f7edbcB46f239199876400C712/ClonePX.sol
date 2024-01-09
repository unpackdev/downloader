// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

abstract contract Parent {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract ClonePX is ERC721Enumerable, Ownable {
  using SafeMath for uint256;

  uint constant public clonexSupply = 500;
  uint constant public freeSupply = 1000;
  uint constant public paidSupply = 4000;
  uint256 public mintPrice = 0.04 ether;

  uint public clonexMintCount = 0;
  uint public freeMintCount = 0;
  uint public paidMintCount = 0;
  uint public freeMintLimit = 3;
  uint public batchLimit = 10;

  bool public mintStarted = false;
  bool public ableToReserve = true;
  string public baseURI = "https://gateway.pinata.cloud/ipfs/QmXN6LWZBz5PVfnqfJR6ZLtqVTffKsnvcmApBYPbEV4ARx/"; // Init to preveal uri
  Parent private parent;

  mapping(address => uint256) public clonexWalletMintMap;
  mapping(address => uint256) public freeWalletMintMap;

  constructor(address parentAddress) ERC721("ClonePX", "CPX") {
    parent = Parent(parentAddress);
  }

  function clonexMint(uint tokensToMint) public {
    require(mintStarted, "Mint is not started");
    require(clonexMintCount.add(tokensToMint) <= clonexSupply, "Minting exceeds supply");

    uint balance = parent.balanceOf(msg.sender);
    require(balance.sub(clonexWalletMintMap[msg.sender]) >= tokensToMint, "Insufficient CloneX tokens.");

    uint256 supply = totalSupply();
    for(uint16 i = 1; i <= tokensToMint; i++) {
      _safeMint(msg.sender, supply + i);
      clonexMintCount++;
      clonexWalletMintMap[msg.sender]++;
    }
  }

  function freeMint(uint tokensToMint) public {
    require(mintStarted, "Mint is not started");
    require(freeMintCount.add(tokensToMint) <= freeSupply, "Minting exceeds supply");
    require(freeWalletMintMap[msg.sender].add(tokensToMint) <= freeMintLimit, "Too many free mints");

    uint256 supply = totalSupply();
    for(uint16 i = 1; i <= tokensToMint; i++) {
      _safeMint(msg.sender, supply + i);
      freeWalletMintMap[msg.sender]++;
    }
  }

  function mint(uint tokensToMint) public payable {
    require(mintStarted, "Mint is not started");
    require(tokensToMint <= batchLimit, "Not in batch limit");
    require(paidMintCount.add(tokensToMint) <= paidSupply, "Minting exceeds supply");
    uint256 price = tokensToMint.mul(mintPrice);
    require(msg.value >= price, "Not enough eth sent");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value.sub(price));
    }

    uint256 supply = totalSupply();
    for(uint16 i = 1; i <= tokensToMint; i++) {
      _safeMint(msg.sender, supply + i);
      paidMintCount++;
    }
  }

  function setPrice(uint256 newPrice) public onlyOwner() {
    mintPrice = newPrice;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
		baseURI = newBaseURI;
	}

  function startMint() external onlyOwner {
    mintStarted = true;
  }

  function pauseMint() external onlyOwner {
    mintStarted = false;
  }

  function reserveLegendaries() public onlyOwner {
    require(ableToReserve, "Already reserved legendaries.");
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= 10; i++) {
      _safeMint(msg.sender, supply + i);
    }
    ableToReserve = false;
  }
}