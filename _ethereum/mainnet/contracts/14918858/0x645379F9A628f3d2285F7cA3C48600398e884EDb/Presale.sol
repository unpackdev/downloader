// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";

contract ApeSale is Ownable {

  bool public saleActive;
  mapping(address => uint256) public purchasedShares;
  uint256 public totalShares;
  uint256 public maxShares;
  uint256 public price;
  uint256 public immutable maxDaiPerTX;

  IERC20 public immutable DAI;
  IERC20 public APE;

  constructor(address dai, uint256 maxTotal, uint256 maxDai, uint256 _price) {
    DAI = IERC20(dai);
    maxShares = maxTotal;
    maxDaiPerTX = maxDai;
    price = _price;
  }

  function setPrice(uint256 _price) public onlyOwner {
      price = _price;
  }
  function setMaxShares(uint256 _max) public onlyOwner {
    require(totalShares < _max, "Cannot drop below existing supply");
    maxShares = _max;
  }
  function startSale() public onlyOwner {
      saleActive = true;
  }
  function setApe(address _ape) public onlyOwner {
      APE = IERC20(_ape);
  }

  function enter(uint256 amount) public {
    require(saleActive == true, "Sale inactive");
    uint256 shares = (amount * 1e18) / price;
    require(totalShares + shares <= maxShares, "Sale has ended");
    require(amount <= maxDaiPerTX, "Purchase too high");
    DAI.transferFrom(msg.sender, owner(), amount);
    totalShares = totalShares + shares;
    purchasedShares[msg.sender] = purchasedShares[msg.sender] + shares;
  }

  function claim() public {
    require(address(APE) != address(0), "Claim inactive");
    uint256 claimAmount = purchasedShares[msg.sender];
    require(claimAmount > 0, "No claim");
    purchasedShares[msg.sender] = 0;
    APE.transfer(msg.sender, claimAmount);
  }

}
