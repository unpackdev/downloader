// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// Inspired/copied from bastardganpunks.club and others ;)
contract CryptoCandies is ERC721, Ownable {
  using SafeMath for uint256;
  bool public hasSaleStarted = false;
  uint public constant CANDY_LIMIT = 5000;
  uint private constant GIVEAWAY_LIMIT = 20;
  uint public donationSum = 0; // how much has been set aside/has been donated
  address payable public treasuryAddress;
  address payable public donationsAddress;

  constructor(address payable _treasuryAddress, address payable _donationsAddress) ERC721("CryptoCandies", "CRYPTOCANDIES") {
    treasuryAddress = _treasuryAddress;
    donationsAddress = _donationsAddress;
  }

  // Candy is getting expensive!
  function calculatePrice() public view returns (uint256) {
      require(hasSaleStarted == true, "CryptoCandies aren't yet available");
      require(totalSupply() < CANDY_LIMIT, "Unfortunately there are no more CryptoCandies available :(");

      uint currentSupply = totalSupply();
      if (currentSupply >= 4950) {
          return 1000000000000000000;        // 4950-4999: 1.0 ETH
      } else if (currentSupply >= 4250){
          return 600000000000000000;         // 4250-4949: 0.6 ETH
      } else if (currentSupply >= 3250){
          return 400000000000000000;         // 3250-4249: 0.4 ETH
      } else if (currentSupply >= 1250){
          return 200000000000000000;         // 1250-3249: 0.2 ETH
      } else if (currentSupply >= 500){
          return 100000000000000000;         //  500-1249: 0.1 ETH
      } else if (currentSupply >= 100){
          return 50000000000000000;          //   100-499: 0.05 ETH
      } else if (currentSupply >= 50){
          return 20000000000000000;          //     50-99: 0.02 ETH
      } else {
          return 10000000000000000;          //      0-49: 0.01 ETH
      }
  }

  // What candies do I have?
  function listCandiesForOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;
        for (index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }
  }

  // Treat yourself!
  function buyMultipleCandies(uint256 numCandies) external payable {
    require(totalSupply() < CANDY_LIMIT, "We are all out of CryptoCandy :(");
    require(numCandies > 0 && numCandies <= 20, "You can only buy 1 to 20 candies at a time");
    require(totalSupply().add(numCandies) <= CANDY_LIMIT, "There aren't enough candies left :(");
    uint256 totalPrice = calculatePrice().mul(numCandies);
    require(msg.value >= totalPrice, "Ether value sent is below the price");

    treasuryAddress.transfer(totalPrice.mul(8).div(10)); // send to treasury account
    uint256 amountToDonate = totalPrice.mul(2).div(10);
    donationsAddress.transfer(amountToDonate); // send to donations account
    donationSum = donationSum + amountToDonate;

    for (uint i = 0; i < numCandies; i++) {
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }
  }

  // OWNER ONLY

  function startSale() public onlyOwner {
    hasSaleStarted = true;
  }

  function pauseSale() public onlyOwner {
    hasSaleStarted = false;
  }

  // Gives owner candies for friends :)
  function reserveGiveawaySupply(uint256 numCandies) external onlyOwner {
    uint currentSupply = totalSupply();
    require(totalSupply().add(numCandies) <= GIVEAWAY_LIMIT, "Exceeded giveaway supply");
    require(hasSaleStarted == false, "Sale has already started");
    uint256 index;
    for (index = 0; index < numCandies; index++) {
        _safeMint(owner(), currentSupply + index);
    }
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
}
