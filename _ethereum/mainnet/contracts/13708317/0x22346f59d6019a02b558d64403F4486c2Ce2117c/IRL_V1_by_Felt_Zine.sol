/* 
#  ██████╗ ██████╗     ██╗██████╗ ██╗         ██╗   ██╗ ██╗          
#  ╚════██╗██╔══██╗    ██║██╔══██╗██║         ██║   ██║███║          
#   █████╔╝██║  ██║    ██║██████╔╝██║         ██║   ██║╚██║          
#   ╚═══██╗██║  ██║    ██║██╔══██╗██║         ╚██╗ ██╔╝ ██║          
#  ██████╔╝██████╔╝    ██║██║  ██║███████╗     ╚████╔╝  ██║          
#  ╚═════╝ ╚═════╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═══╝   ╚═╝          
#                                                                    
#  ███████╗███████╗██╗     ████████╗    ███████╗██╗███╗   ██╗███████╗
#  ██╔════╝██╔════╝██║     ╚══██╔══╝    ╚══███╔╝██║████╗  ██║██╔════╝
#  █████╗  █████╗  ██║        ██║         ███╔╝ ██║██╔██╗ ██║█████╗  
#  ██╔══╝  ██╔══╝  ██║        ██║        ███╔╝  ██║██║╚██╗██║██╔══╝  
#  ██║     ███████╗███████╗   ██║       ███████╗██║██║ ╚████║███████╗
#  ╚═╝     ╚══════╝╚══════╝   ╚═╝       ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
#                                                                    
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract
IRL_V1_by_Felt_Zine
is
ERC721Enumerable,
IERC2981,
ReentrancyGuard,
Ownable
{
  using Counters for Counters.Counter;

  constructor (string memory customBaseURI_)
    ERC721("3D IRL V1 by Felt Zine", "irlv1")
  {
    customBaseURI = customBaseURI_;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 10;

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 100;

  uint256 public constant MAX_MULTIMINT = 10;

  uint256 public constant PRICE = 100000000000000000;

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");

    if (allowedMintCount(_msgSender()) >= count) {
      updateMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 10 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.1 ETH per item"
    );

    for (uint256 i = 0; i < count; i++) {
      _safeMint(_msgSender(), totalSupply());
    }
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  /** PAYOUT **/

  function withdraw() public {
    uint256 balance = address(this).balance;

    payable(owner()).transfer(balance);
  }

  /** ROYALTIES **/

  function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 1000) / 10000);
  }
}

// Contract created with Studio 721 v1.3.0
// https://721.so