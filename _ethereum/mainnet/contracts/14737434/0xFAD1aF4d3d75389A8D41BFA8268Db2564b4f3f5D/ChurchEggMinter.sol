// contracts/ChurchEggMinter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ISwapRouter.sol";
import "./ChurchEggs.sol";

contract ChurchEggMinter is AccessControl {

  uint256 public constant MAX_SUPPLY = 7777;
  uint256 public priceDelta = 7 ether / 100000;
  uint256 public price = 7 ether / 100000;
  bool public saleEnabled = true;
  uint256 public counter = 1;
  uint256 public eggsMinted;
  event EggsBought(address buyer, uint256 eggsBought, uint256[77] eggIndexes);

  address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //uniswap

  uint256 discountPrecision = 10000;
  IERC20 Prayers = IERC20(0x02C3E015D33237241eD6E78bfa39984FF8caF0f0);
  ChurchEggs public Eggs;

  /* Events */
  event Withdraw(uint256 amount);
  event BuyAndBurnChurch(uint256 amount);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setEggAddress(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
    Eggs = ChurchEggs(to);
  }

  // Return info about church and prayers to web3
  function getInfo(address user) external view returns (uint256[] memory) {
    uint256[] memory info = new uint256[](7);
    info[0] = price;
    info[2] = discountPrecision;
    info[3] = eggsMinted;
    info[4] = priceDelta;

    if (user != address(0)) {
      info[1] = discount(user);
      info[5] = user.balance;
      info[6] = Eggs.balanceOf(user);
    }

    return info;
  }

  function mintBunch(uint256[] memory toMint) public onlyRole(DEFAULT_ADMIN_ROLE) {
    eggsMinted += toMint.length;
    for (uint256 i = 0; i < toMint.length; i++) {
      require(toMint[i] != 0 && toMint[i] <= MAX_SUPPLY, "Invalid eggId");
      Eggs.mintEgg(msg.sender, toMint[i]); 
    }
  }

  function discount(address user) public view returns (uint256){
    uint256 userDiscount = 2 * Prayers.balanceOf(user);
    if (userDiscount > Prayers.totalSupply() / 2)
      userDiscount = Prayers.totalSupply() / 2;

    return discountPrecision * userDiscount / Prayers.totalSupply();
  }

  function buy(uint256 amountToBuy) public payable {
    require(block.timestamp > 1652102227, "Public sale has not yet started!");
    require(amountToBuy > 0 && amountToBuy <= 77, "Invalid amount");
    require(saleEnabled, "Sale disabled");

    uint256 userPrice = amountToBuy * price;
    userPrice = (discountPrecision - discount(msg.sender)) * userPrice / discountPrecision;

    require(msg.value >= userPrice, "Not enough ETH supplied");

    uint256[77] memory eggIdsToMint;
    uint256 eggsToMint;
    uint256 i = counter;

    while (eggsToMint < amountToBuy) {
      if (!Eggs.exists(i)) {
        eggIdsToMint[eggsToMint] = i;
        eggsToMint++;
      }
      counter = ++i;
      if (i > MAX_SUPPLY) {
        saleEnabled = false;
        break;
      }
    }

    if (msg.value > userPrice)
      payable(msg.sender).transfer(msg.value - userPrice);

    emit EggsBought(msg.sender, eggsToMint, eggIdsToMint);
    price += eggsToMint * priceDelta;
    eggsMinted += eggsToMint;

    for (uint256 j = 0; j < eggsToMint; j++)
      Eggs.mintEgg(msg.sender, eggIdsToMint[j]); 
  }

  function setSaleEnabled(bool to) public onlyRole(DEFAULT_ADMIN_ROLE) {
    saleEnabled = to;
  }

  function setCounter(uint256 to) public onlyRole(DEFAULT_ADMIN_ROLE) {
    counter = to;
  }

  function setPrice(uint256 to) public onlyRole(DEFAULT_ADMIN_ROLE) {
    price = to;
  }

  function withdraw(uint256 minChurchToBurn) public onlyRole(DEFAULT_ADMIN_ROLE) {
    buyAndBurnChurch(minChurchToBurn);
    uint256 amount = address(this).balance;
    payable(msg.sender).transfer(amount); 
    emit Withdraw(amount);
  }

  function buyAndBurnChurch(uint256 minTokensOut) internal {
    uint256 amount = 777 * address(this).balance / 10000;
    emit BuyAndBurnChurch(amount);

    ISwapRouter(routerAddress).swapExactETHForTokens{ value: amount }(
      minTokensOut,
      wethToChurchPath(),
      0xdEAD000000000000000042069420694206942069,
      block.timestamp + 1000
    );
  }

  function computeChurchToBurn() external view returns (uint256) {
    uint256 balance = address(this).balance;
    if (balance == 0) return 0;

    uint256[] memory amountsOut = ISwapRouter(routerAddress).getAmountsOut(
      777 * balance / 10000, wethToChurchPath()
    );
    return amountsOut[1];
  }

  function wethToChurchPath() public pure returns(address[] memory) {
    address[] memory addressPath = new address[](2);
    address _wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _churchAddress = 0x71018cc3D0CCdc7E10C48550554cE4D4E3afd9C1;

    addressPath[0] = _wethAddress;
    addressPath[1] = _churchAddress;
    return addressPath;
  }

}
