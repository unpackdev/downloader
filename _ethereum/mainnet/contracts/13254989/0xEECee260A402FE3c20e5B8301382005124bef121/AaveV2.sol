// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <dev@sherlock.xyz> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IAaveIncentivesController.sol";
import "./IStakeAave.sol";
import "./IAToken.sol";

import "./IStrategy.sol";

contract AaveV2 is IStrategy {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ERC20;

  ILendingPoolAddressesProvider public constant lpAddressProvider =
    ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
  IAaveIncentivesController public immutable aaveIncentivesController;

  ERC20 public immutable override want;
  IAToken public immutable aWant;

  address public immutable sherlock;
  address public immutable aaveLmReceiver;

  modifier onlySherlock() {
    require(msg.sender == sherlock, 'sherlock');
    _;
  }

  constructor(
    IAToken _aWant,
    address _sherlock,
    address _aaveLmReceiver
  ) {
    aWant = _aWant;
    want = ERC20(_aWant.UNDERLYING_ASSET_ADDRESS());
    aaveIncentivesController = _aWant.getIncentivesController();

    sherlock = _sherlock;
    aaveLmReceiver = _aaveLmReceiver;
  }

  /**
    View methods
  */

  function getLp() internal view returns (ILendingPool) {
    return ILendingPool(lpAddressProvider.getLendingPool());
  }

  function balanceOf() public view override returns (uint256) {
    return aWant.balanceOf(address(this));
  }

  /**
    Sherlock strategy methods
  */

  function deposit() external override {
    ILendingPool lp = getLp();
    uint256 amount = want.balanceOf(address(this));
    require(amount != 0, 'ZERO_AMOUNT');

    if (want.allowance(address(this), address(lp)) < amount) {
      want.safeApprove(address(lp), type(uint256).max);
    }

    lp.deposit(address(want), amount, address(this), 0);
  }

  function withdrawAll() external override onlySherlock returns (uint256) {
    ILendingPool lp = getLp();
    if (balanceOf() == 0) {
      return 0;
    }
    return lp.withdraw(address(want), type(uint256).max, msg.sender);
  }

  function withdraw(uint256 _amount) external override onlySherlock {
    require(_amount != type(uint256).max, 'MAX');

    ILendingPool lp = getLp();
    require(lp.withdraw(address(want), _amount, msg.sender) == _amount, 'AAVE');
  }

  function claimRewards() external {
    address[] memory assets = new address[](1);
    assets[0] = address(aWant);

    aaveIncentivesController.claimRewards(assets, type(uint256).max, aaveLmReceiver);
  }

  function sweep(address _receiver, IERC20[] memory _extraTokens) external override onlySherlock {
    for (uint256 i; i < _extraTokens.length; i++) {
      IERC20 token = _extraTokens[i];
      token.safeTransfer(_receiver, token.balanceOf(address(this)));
    }
    selfdestruct(payable(_receiver));
  }
}
