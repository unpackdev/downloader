// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC20Burnable.sol";

/**
* On-chain marketplace pricing state/logic for JungleverseItem ERC1155 tokens.
* Admins will be able to mint supplies of ERC1155 tokens to this address 
* and sell them here for purchase in JUNGLE as an official "Primary Sale".
* All sale proceeds go to the contract which can be redeemed by the owner.
*/
contract JungleMarketplace is IERC1155Receiver, Ownable {

  IERC1155 public jungleverseItem;
  ERC20Burnable public jungleToken;
  uint256 public maxPurchaseAmount;

  mapping(uint256 => uint256) public tokenIdToJunglePrice;
  mapping(address => mapping(uint256 => uint256)) public userPurchasedTokenIdAmount;

  // NOTE: You'll also need to run setJungleverseItemContract before creating listings.
  constructor(address jungleTokenAddress) {
    jungleToken = ERC20Burnable(jungleTokenAddress);
  }

  /* 
  * Places a JungleverseItem "for sale" on the marketplace, priced in $JUNGLE. 
  * NOTE: SINCE THIS IS A CONTRACT-ONLY OPERATION, SUPPLY THE AMOUNT IN "WHOLE" $JUNGLE.
  * SOLIDITY WILL MULTIPLY THE 10^18 TO ENSURE LESS FAT-FINGERING/HUMAN ERROR.
  * 
  * NOTE: To fetch market prices, utilize the public `tokenIdToJunglePrice`. 
  * The client must manually dictates what tokenIds will be shown at a time.
  * This is to save gas for read-path calls.
  */
  function createMarketListing(
    uint256 tokenId,
    uint256 priceInJungleInteger
  ) public onlyOwner {
    require(address(jungleverseItem) != 0x0000000000000000000000000000000000000000, 
      "Please configure sellable ERC1155 contract via setJungleverseItemContract.");
    require(priceInJungleInteger > 0, "Price must be at least 1 $JUNGLE. BE SURE TO USE THE INTEGER VALUE.");

    tokenIdToJunglePrice[tokenId] = priceInJungleInteger * 1e18;
  }

  /* 
  * Creates the sale of a JungleverseItem from the "seller" to the msg.sender.
  * Transfers ownership of "amount" instances of an ERC1155 with a given id, 
  * and $JUNGLE from the buyer to the contract based on the tokens price.
  */
  function createMarketSale(uint256 tokenId, uint256 amount) public {
    require(address(jungleverseItem) != 0x0000000000000000000000000000000000000000, 
      "Please configure sellable ERC1155 contract via setJungleverseItemContract.");
    require(amount > 0, "Purchasable amount must be non-zero.");

    uint price = tokenIdToJunglePrice[tokenId] * amount;
    uint supply = jungleverseItem.balanceOf(address(this), tokenId);
    require(price > 0, "This item is not listed for sale!");
    require(supply > 0, "This item is sold out.");

    uint256 buyerJungleBalance = jungleToken.balanceOf(msg.sender);
    require(buyerJungleBalance >= price, "Insufficient funds: Not enough $JUNGLE for sale price");

    require(userPurchasedTokenIdAmount[msg.sender][tokenId] + amount <= maxPurchaseAmount, "Max amount");
    userPurchasedTokenIdAmount[msg.sender][tokenId] += amount;

    jungleToken.burnFrom(msg.sender, price);
    jungleverseItem.safeTransferFrom(address(this), msg.sender, tokenId, amount, "0x0");
  }


  /*********** ADMIN FUNCTIONS ************/


  /* 
  * Sets the ERC1155 contract which the Marketplace is holding and selling.
  * 
  * In conjunction with `deleteMarketListing` and `withdrawAllJungle`, allows owner to  
  * migrate Marketplace to sell items from a different ERC1155 NFT contract.
  */
  function setJungleverseItemContract(IERC1155 _contract) public onlyOwner {
    jungleverseItem = _contract;
  }

  function setMaxPurchaseAmount(uint256 _maxPurchaseAmount) public onlyOwner {
    maxPurchaseAmount = _maxPurchaseAmount;
  }

  /* 
  * Delete item price listing from Marketplace. 
  * Only do this if its sold out and you don't want to it show up on the site again.
  */
  function deleteMarketListing(uint256 _tokenId) public onlyOwner {
    delete tokenIdToJunglePrice[_tokenId];
  }


  function withdrawJungle(uint256 _amount) public onlyOwner {
    uint256 jungleBalance = jungleToken.balanceOf(address(this));
    require(jungleBalance >= _amount, "Insufficient funds: not enough $JUNGLE");
    jungleToken.transfer(msg.sender, _amount);
  }

  function withdrawAllJungle() public onlyOwner {
    uint256 jungleBalance = jungleToken.balanceOf(address(this));
    require(jungleBalance > 0, "No $JUNGLE within this contract");
    jungleToken.transfer(msg.sender, jungleBalance);
  }


  function withdrawItems(uint256 _tokenId, uint256 _amount) public onlyOwner {
    uint256 contractBalance = jungleverseItem.balanceOf(address(this), _tokenId);
    require(contractBalance >= _amount, "Insufficient funds: not enough unsold Items");
    jungleverseItem.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0x0");
  }

  function withdrawAllItems(uint256 _tokenId) public onlyOwner {
    uint256 contractBalance = jungleverseItem.balanceOf(address(this), _tokenId);
    require(contractBalance > 0, "No unsold Items left on the contract!");
    jungleverseItem.safeTransferFrom(address(this), msg.sender, _tokenId, contractBalance, "0x0");
  }


  // Just in case anyone sends us any random shitcoins ;)
  function withdrawErc20(address erc20Contract, uint256 _amount) public onlyOwner {
    uint256 erc20Balance = jungleToken.balanceOf(address(this));
    require(erc20Balance >= _amount, "Insufficient funds: not enough ERC20");
    IERC20(erc20Contract).transfer(msg.sender, _amount);
  }


  // Required for SC to hold ERC1155. Copypasta from OZ cuz node bein caca.
  // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/utils/ERC1155Holder.sol
  function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
      return interfaceId == type(IERC1155Receiver).interfaceId;
  }

}