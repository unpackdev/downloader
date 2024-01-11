// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract KaijuMfers is ERC721A, Ownable {
  using SafeERC20 for IERC20;

  uint256 price;
  uint256 priceRwaste;
  uint16 maxSupply;
  uint16 maxFreeSupply;
  address Rwaste;
  bool saleActive = false;
  bool freeSupplyRemaining = true;

  constructor(uint16 supply, uint16 freeSupply, address rwaste) ERC721A("Kaiju Mfers", "KMFERS") {
    price = 0.0333 ether;
    priceRwaste = 20 ether;
    maxSupply = supply;
    maxFreeSupply = freeSupply;
    Rwaste = rwaste;
    _mint(50);
  }

  function setSale() public onlyOwner {
    saleActive =! saleActive;
  }

  function changePrice(uint256 _newPrice) public onlyOwner{
    price = _newPrice;
  }

  function changePriceRwaste(uint256 _newPrice) public onlyOwner{
    priceRwaste = _newPrice;
  }

  function collect() public onlyOwner {
    uint256 bal = address(this).balance;
    require(bal > 0, "No ether");
    payable(msg.sender).transfer(bal);
  }

  function collectRwaste() public onlyOwner{
    uint256 bal = IERC20(Rwaste).balanceOf(address(this));
    require(bal > 0, "No Rwaste to collect");
    IERC20(Rwaste).safeTransfer(owner(), bal);
  }

  function mint(uint256 _quantity) public payable onlyHuman{
    require(saleActive, "We are not yet minting");
    if(freeSupplyRemaining){
      require(balanceOf(msg.sender) == 0, "No free mints for already members");
    }
    uint256 quantity = _checkQuantity(_quantity);
    _checkPricing(quantity);
    _endFreesupply(quantity);
    _mint(quantity);
  }

  function mintWithRwaste(uint256 _quantity, uint256 _cost) public onlyHuman{
    require(saleActive, "We are not yet minting");
    uint256 quantity = _checkQuantity(_quantity);
    if(!freeSupplyRemaining){
      require(_cost == quantity * priceRwaste, "Wrong amount of Rwaste");
      require(IERC20(Rwaste).balanceOf(msg.sender) >= _cost, "Not enough Rwaste");
    }else{
      require(balanceOf(msg.sender) == 0, "No free mints for already members");
    }
    IERC20(Rwaste).safeTransferFrom(msg.sender, address(this), _cost);
    _mint(quantity);
  }

  //@dev check the mint supply and quantity allowed for mints and free mints
  function _checkQuantity(uint256 quantity) private view returns(uint256) {

    require(totalSupply() < maxSupply, "We are sold out !!");
    require(quantity <= 10, "Can't mint more than 10 at once");

    if(freeSupplyRemaining && quantity > 5){
      quantity = 5;
    }
    if(totalSupply() + quantity > maxFreeSupply && freeSupplyRemaining){
      while(totalSupply() + quantity > maxFreeSupply){
       quantity--;
      }
    }
    if(totalSupply() + quantity > maxSupply){
      while(totalSupply() + quantity > maxSupply){
       quantity--;
      }
    }
    return quantity;
  }

  //@dev reimburse people for the free mint and if they paid too much
  function _checkPricing(uint256 quantity) private{
    if(freeSupplyRemaining == false){
      uint256 checkout = price * quantity;
      require(msg.value >= checkout, "Wrong ether value");
      
      if(msg.value > checkout){
        uint256 overpaid = msg.value - checkout;
        payable(msg.sender).transfer(overpaid);
      }
    }else{
      uint256 overpaid = msg.value;
      payable(msg.sender).transfer(overpaid);
    }  
  }

  function _mint(uint256 quantity) private {
   _safeMint(msg.sender, quantity);
  }

  function _endFreesupply(uint256 quantity) private {
    if(totalSupply() + quantity == maxFreeSupply){
      freeSupplyRemaining = false;
    }
  }

  modifier onlyHuman() {
    require(tx.origin == msg.sender, "Robots cannot take part in the sale");
    _;
  }
}