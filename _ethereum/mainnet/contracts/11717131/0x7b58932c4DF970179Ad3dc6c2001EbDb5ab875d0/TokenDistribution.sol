// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Governable.sol";
import "./IUniswap.sol";

contract TokenDistribution is Governable, Pausable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SafeMath for uint112;

  IERC20  public immutable GEMLY;
  IERC20  public immutable COLLATERAL;
  address public immutable LP;

  uint256 public price;
  uint256 public progress;
  uint256 public totalSupply;
  
  address private constant  UNIROUTER     = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant  FACTORY       = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address private           WETHAddress   = IUniswap(UNIROUTER).WETH();
  uint256 public constant   DECIMALS      = 10**18;

  event Bought(address indexed account, uint256 amount);

  constructor(address _governance, IERC20 _gemly, IERC20 _collateral) public
    Governable(_governance)
  {
    GEMLY = _gemly;
    COLLATERAL = _collateral;
    LP = IUniswap(FACTORY).getPair(WETHAddress, address(_collateral));
  }

  // TODO: Make it work once only, have other method for price change...
  function init(uint256 _price, uint256 _totalSupply) external onlyGovernance {
    require(_price > 0);

    price = _price;
    totalSupply = _totalSupply;
  }

  function pause() external onlyGovernance {
    super._pause();
  }

  function unpause() external onlyGovernance {
    super._unpause();
  }

  function offerInCollateral(uint256 _amount) public view returns(uint256) {
    uint256 amount = _amount.mul(DECIMALS).div(price);
    return amount;
  }

  function offerInEth(uint256 _amount) public view returns(uint256) {
    uint256 amount = estimatedCollateralForETH(_amount);
    return offerInCollateral(amount);
  }

  function canBuy(uint256 _amount) public view returns(bool) {
    uint256 amount = offerInCollateral(_amount);
    return !paused() && progress.add(amount) <= totalSupply;
  }

  function canBuyWithEth(uint256 _amount) public view returns(bool) {
    uint256 amount = estimatedCollateralForETH(_amount);
    return canBuy(amount);
  }

  function buy(uint256 _amount) public {
    require(canBuy(_amount), "Exceeded total supply limit or paused");

    COLLATERAL.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 amount = offerInCollateral(_amount);
    GEMLY.safeTransfer(msg.sender, amount);
    progress = progress.add(amount);

    emit Bought(msg.sender, amount);
  }

  function buyWithEth() public payable {
    require(canBuyWithEth(msg.value), "Exceeded total supply limit or paused");

    uint256 amount = offerInEth(msg.value);
    GEMLY.safeTransfer(msg.sender, amount);
    progress = progress.add(amount);

    emit Bought(msg.sender, amount);
  }

  function withdrawGemly() external onlyGovernance {
    uint256 balance = GEMLY.balanceOf(address(this));
    GEMLY.safeTransfer(msg.sender, balance);
  }

  function withdrawCollateral() external onlyGovernance {
    uint256 balance = COLLATERAL.balanceOf(address(this));
    COLLATERAL.safeTransfer(msg.sender, balance);
  }

  function withdrawEth() external onlyGovernance {
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success);
  }

  function estimatedCollateralForETH(uint256 _amount) internal view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IUniswap(LP).getReserves();
    if(IUniswap(LP).token0() == address(COLLATERAL)) {
      return reserve0.mul(_amount).div(reserve1);
    } else {
      return reserve1.mul(_amount).div(reserve0);
    }
  }

  receive() external payable {
    buyWithEth();
  }
}
