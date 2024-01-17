// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract SteamPumpkins is ERC721A, Ownable, ReentrancyGuard {
     string public baseURI = "";
  uint public maxSupply = 333;
  uint256 public costForNFT = 0.003 ether;
  uint public maxPerWallet = 2;
  bool public activated = false;
  constructor() ERC721A("SteamPumpkins", "STMPKN"){}

  function mint(uint256 amount) external payable
  {
    require(activated, "contract not activated yet");
    require(amount>0, "Amount has to be greater than 1");
    require(msg.sender == tx.origin, "Smart Contracts can't mint");
    require(totalSupply() + amount <= maxSupply,"Sold out");
    require(_numberMinted(msg.sender) + amount <= maxPerWallet, "2 per wallet");

    if(amount == 1)
      require(msg.value >= costForNFT, "Insufficient funds!");

    if(amount == 2)
      require(msg.value >= (2 * costForNFT), "Insufficient funds!");

    _safeMint(msg.sender, amount);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function setPrice(uint256 price) external onlyOwner {
    costForNFT = price;
  }


  function flipState() external onlyOwner {
    if (totalSupply() == 0)
      _safeMint(msg.sender, 1);

    activated = !activated;
  }

  function giveawayMint(address[] calldata to, uint256 amount) external onlyOwner {
    require(totalSupply() + amount <= maxSupply);
    for (uint i = 0; i < to.length; i++)
    {
      _safeMint(to[i], amount);
    }
      
}

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool wallet, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(wallet, "Failed");

  }


}