// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol"; 
import "./Context.sol"; 
import "./Strings.sol"; 
import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./ERC721A.sol";

contract LoonBirds is ERC721A, Ownable, ReentrancyGuard {

  string public        baseURI           = "ipfs://bafybeifvtunpilavdcghdsw6pjw6gpnjvhvvq45qiuyd3qdgoil2zexxry/";
  string public        contractURI       = "";
  uint public          price             = 0.002 ether;
  uint public          maxPerTx          = 10;
  uint public          maxPerWallet      = 10;
  uint public          totalFree         = 1024;
  uint public          maxSupply         = 4096;
  uint public          nextOwnerToExplicitlySet;
  bool public          mintEnabled;

  constructor() ERC721A("LoonBirds", "LB"){}

  enum TokenURIMode {
    MODE_ONE,
    MODE_TWO
  }

  TokenURIMode private tokenUriMode = TokenURIMode.MODE_TWO;

  function mint(uint256 amt) external payable
  {
    uint cost = price;
    if(totalSupply() + amt < totalFree + 1) {
      cost = 0;
    }
    require(mintEnabled, "Minting is not live yet.");
    require(msg.sender == tx.origin,"Be yourself, honey.");
    require(msg.value == amt * cost,"Please send the exact amount.");
    require(totalSupply() + amt < maxSupply + 1,"No more Apes available");
    require(numberMinted(msg.sender) + amt <= maxPerWallet,"Too many per wallet!");
    require(amt < maxPerTx + 1, "Max per TX reached.");

    _safeMint(msg.sender, amt);
  }

  function toggleMintEnabled() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function setTotalFree(uint256 totalFree_) external onlyOwner {
      totalFree = totalFree_;
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

  function setTokenURIMode(uint256 mode) external onlyOwner {
    if (mode == 2) {
      tokenUriMode = TokenURIMode.MODE_TWO;
    } else {
      tokenUriMode = TokenURIMode.MODE_ONE;
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) 
  {
        require(_exists(_tokenId), "Token does not exist.");
        if (tokenUriMode == TokenURIMode.MODE_TWO) {
          return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId)
            )
          ) : "";
        } else {
          return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
          ) : "";
        }
    }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}