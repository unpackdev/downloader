//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./IApeNFT.sol";

/**
  ApingMarket is the market & Gallery contract
*/

contract ApingMarket is Ownable, ReentrancyGuard {

  using SafeMath for uint256;

  constructor() public Ownable(){}

  // Each series is a separate contract.
  // Logistic wise, the market should be set as minter before the sale
  // After the sale, the market will renounce its minter role.
  // This market should be the only minter when the sale is on-going.

  struct ArtSeries {
    uint256 id;
    address nftAddress;
    uint256 currentMinted;
    uint256 numberOfArts;
  }

  ArtSeries[] public artSeriesInfo;

  mapping (address => uint256) public userWithdrawable;

  function startSeriesSale(address nftAddress, uint256 numberOfArts) public onlyOwner {
    uint256 newId = artSeriesInfo.length;

    artSeriesInfo.push(ArtSeries({
      id: newId,
      nftAddress: nftAddress,
      currentMinted: 0,
      numberOfArts: numberOfArts
    }));
  }

  function justApeIn(uint256 seriesId, uint256 num) payable public nonReentrant {
    ArtSeries storage aSeries = artSeriesInfo[seriesId];
    require(IApeNFT(aSeries.nftAddress).validOrder(msg.sender, num), "Order is not valid");
    require(aSeries.currentMinted.add(num) <= aSeries.numberOfArts, "Cannot mint more than designated");

    // inquire price from ApeIn NFTs: ERC721 or ERC1155
    uint256 totalPrice = IApeNFT(aSeries.nftAddress).quote(num);

    require(totalPrice <= msg.value, "Ether sent is less than quote.");

    // if the value sent is more than the price, than we should allow the user to
    // withdraw the excess from this contract later
    if(msg.value > totalPrice) {
      uint256 diffPrice = msg.value.sub(totalPrice);
      userWithdrawable[msg.sender] = userWithdrawable[msg.sender].add(diffPrice);
    }
    aSeries.currentMinted = aSeries.currentMinted.add(num);
    IApeNFT(aSeries.nftAddress).mintBatch{value: totalPrice}(msg.sender, num);
  }

  function justApeInSpecific(uint256 seriesId, uint256 id) payable public nonReentrant {
    ArtSeries storage aSeries = artSeriesInfo[seriesId];
    require(IApeNFT(aSeries.nftAddress).validOrder(msg.sender, id), "Order is not valid");

    // inquire price from ApeIn NFTs: ERC721 or ERC1155
    uint256 totalPrice = IApeNFT(aSeries.nftAddress).quoteSpecific(id);

    require(totalPrice <= msg.value, "Ether sent is less than quote.");

    // if the value sent is more than the price, than we should allow the user to
    // withdraw the excess from this contract later
    if(msg.value > totalPrice) {
      uint256 diffPrice = msg.value.sub(totalPrice);
      userWithdrawable[msg.sender] = userWithdrawable[msg.sender].add(diffPrice);
    }

    IApeNFT(aSeries.nftAddress).mintSpecific{value: totalPrice}(msg.sender, id);
  }

  function quote(uint256 seriesId, uint256 num) view public returns(uint256){
    ArtSeries storage aSeries = artSeriesInfo[seriesId];
    uint256 totalPrice = IApeNFT(aSeries.nftAddress).quote(num);
    return totalPrice;
  }

  /**
    When a user withdraws, he withdraws everything
  */

  function withdrawFunds(address payable target) public nonReentrant {
    uint256 pending = userWithdrawable[msg.sender];
    userWithdrawable[msg.sender] = 0;
    (bool success, ) = target.call{value: pending}("");
    require(success, "Withdraw funds failed.");
  }
}