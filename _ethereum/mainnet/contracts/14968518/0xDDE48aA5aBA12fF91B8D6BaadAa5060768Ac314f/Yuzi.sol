// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";

contract Yuzi is ERC721A, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 public maxSupply= 10000;
  uint256 public constant MAX_SUPPLY_PER_WALLET= 20;
  uint256 private constant TEAM_SUPPLY= 50;
  uint256 public salePriceETH = 0.005 ether;

  bool public isActive = false;
  bool public publicSaleActive = false;

  mapping(address => uint256) public quantityPerWallet;

  string private baseTokenURI = "ipfs://QmaQt2jbCjzcZPPV2QBwftorzawYuR6vrL7X5GBikJxwM6/";


  constructor(
    string memory newBaseURI
  ) ERC721A("Yuzi", "Yuzi") {
    baseTokenURI = newBaseURI;
  }

  modifier onlyEOA() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  
  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function setPrice(uint256 _PriceInWEI) external onlyOwner {
    salePriceETH = _PriceInWEI;
  }


  // Toggle activate/desactivate the smart contract
  function toggleActive() external onlyOwner {
    isActive = !isActive;
  }

  //  Set public sale active / deactive
  function setPublicSaleActive(bool active) external onlyOwner {
    require(publicSaleActive != active, "PublicSale: Active Same State");
    publicSaleActive = active;
  }

  // Mint on Public Sale using ETH
  function publicSaleMint(uint256 _quantity)external payable onlyEOA {
    require(isActive, "Contract not Active");
    require(publicSaleActive, "Sale not Active");
    require(_quantity != 0, "0 Quantity");
    require(totalSupply() + _quantity <= maxSupply, "Over Max Supply");
    require(quantityPerWallet[msg.sender] + _quantity <= MAX_SUPPLY_PER_WALLET, "Over Max Supply Per Wallet");

    uint256 payForCount = _quantity;
    uint256 freeMintCount = quantityPerWallet[msg.sender];

    if (freeMintCount < 1) {
      if (_quantity > 1) {
        payForCount = _quantity - 1;
      } else {
        payForCount = 0;
      }
    }

    require(msg.value >= payForCount * salePriceETH, "Insufficient ETH");

    quantityPerWallet[msg.sender] += _quantity;
    _mint(msg.sender, _quantity);
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return quantityPerWallet[owner];
  }

  function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );


        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

  


  //  Team mint
  function teamMint() external onlyOwner {
    require(
      totalSupply() + TEAM_SUPPLY <= maxSupply,
      "TeamMint: Over Max Supply"
    );

    uint256 maxBatchSize = 10;
    for (uint256 i; i < 5; i++) { 
        _mint(msg.sender, maxBatchSize);
    }

    uint256 remaining = TEAM_SUPPLY % maxBatchSize;
    if (remaining > 0) {
        _mint(msg.sender, remaining);
    }
  }


  //  Withdraw ETH
  function withdrawETH() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Withdraw: Insufficient ETH");

    bool success;
    if(balance > 0){
      (success, ) = payable(msg.sender).call{ value: balance }("");
    }
    require(success, "Withdraw: Failed");
  }

}