// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IRestrictedIndexPool.sol";
import "./IWETH.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

contract UniBurn {
  using SafeMath for uint256;
  using TransferHelper for address;

  IERC20 public constant defi5LP =
    IERC20(0x8dCBa0B75c1038c4BaBBdc0Ff3bD9a8f6979Dd13);
  IERC20 public constant cc10LP =
    IERC20(0x2701eA55b8B4f0FE46C15a0F560e9cf0C430f833);
  IERC20 public constant fffLP =
    IERC20(0x9A60F0A46C1485D4BDA7750AdB0dB1b17Aa48A33);
  IWETH public constant weth =
    IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  IRestrictedIndexPool public constant defi5 =
    IRestrictedIndexPool(0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41);
  IRestrictedIndexPool public constant cc10 =
    IRestrictedIndexPool(0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3);
  IRestrictedIndexPool public constant fff =
    IRestrictedIndexPool(0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413);

  struct PoolData {
    uint96 supply;
    uint72 ethBalance;
    uint88 poolBalance;
  }

  PoolData public fffData =
    PoolData(
      uint96(133274619446277226138),
      uint72(11392283886319598494),
      uint88(1664883434767400933503)
    );

  PoolData public defi5Data =
    PoolData(
      uint96(205228556349547851201),
      uint72(5759526907677680378),
      uint88(8924373539359521982012)
    );

  PoolData public cc10Data =
    PoolData(
      uint96(993232546416253583380),
      uint72(25711183462534811),
      uint88(74090838958998997067316924)
    );

  function _redeem(
    IRestrictedIndexPool pool,
    IERC20 pair,
    PoolData storage info
  ) internal {
    uint256 lpBalance = pair.balanceOf(msg.sender);
    require(lpBalance > 0, "ERR_NULL_AMOUNT");
    address(pair).safeTransferFrom(msg.sender, address(0), lpBalance);

    uint256 supply = uint256(info.supply);
    uint256 ethBalance = uint256(info.ethBalance);
    uint256 poolBalance = uint256(info.poolBalance);

    uint256 ethValue = ethBalance.mul(lpBalance) / supply;
    uint256 poolValue = poolBalance.mul(lpBalance) / supply;

    // We don't need to do a safe cast because safemath prevents
    // overflow and the original values are within size range
    info.ethBalance = uint72(ethBalance.sub(ethValue));
    info.poolBalance = uint88(poolBalance.sub(poolValue));
    info.supply = uint96(supply.sub(lpBalance));

    pool.exitPoolTo(msg.sender, poolValue);
    address(msg.sender).safeTransferETH(ethValue);
  }

  receive() external payable {}

  function burnWETH() external {
    weth.withdraw(weth.balanceOf(address(this)));
  }

  function redeemFFFLP() external {
    _redeem(fff, fffLP, fffData);
  }

  function redeemDEFI5LP() external {
    _redeem(defi5, defi5LP, defi5Data);
  }

  function redeemCC10LP() external {
    _redeem(cc10, cc10LP, cc10Data);
  }
}
