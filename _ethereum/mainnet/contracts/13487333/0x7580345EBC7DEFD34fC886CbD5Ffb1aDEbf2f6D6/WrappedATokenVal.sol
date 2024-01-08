// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./FeeBase.sol";
import "./IWETHGateway.sol";
import "./IWERC20Val.sol";

contract WrappedATokenVal is ERC20, FeeBase, IWERC20Val, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint256 public constant MULTIPLIER = 1e18;

  IERC20 public immutable aToken;
  address public immutable lendingPool;
  IWETHGateway public immutable wethGateway;

  uint256 public lastABalance;
  uint256 public totalUnredeemedFee;

  constructor(
    string memory _name,
    string memory _symbol,
    address _aToken,
    address _lendingPool,
    address _wethGateway,
    address _feeToSetter
  ) ERC20(_name, _symbol) FeeBase(_feeToSetter) {
    aToken = IERC20(_aToken);
    lendingPool = _lendingPool;
    wethGateway = IWETHGateway(_wethGateway);
  }

  function pendingFee() public view returns (uint256) {
    if (hasFee()) {
      // Invariant: feeDivisor > 0
      uint256 currentABalance = aToken.balanceOf(address(this));
      if (currentABalance > lastABalance) {
        return currentABalance.sub(lastABalance).div(feeDivisor);
      }
    }
    return 0;
  }

  function totalFee() public view returns (uint256) {
    return pendingFee().add(totalUnredeemedFee);
  }

  function debtToUnderlying(uint256 debtAmount) public view override returns (uint256) {
    uint256 totalDebtSupply = totalSupply();
    if (totalDebtSupply <= 0) {
      return debtAmount.div(MULTIPLIER);
    }
    return debtAmount.mul(aToken.balanceOf(address(this)).sub(totalFee())).div(totalDebtSupply);
  }

  function underlyingToDebt(uint256 underlyingAmount) public view override returns (uint256) {
    uint256 totalUnderlyingSupply = aToken.balanceOf(address(this)).sub(totalFee());
    if (totalUnderlyingSupply <= 0) {
      return underlyingAmount.mul(MULTIPLIER);
    }
    return underlyingAmount.mul(totalSupply()).div(totalUnderlyingSupply);
  }

  function takeFee() external {
    uint256 fee = totalFee();
    if (fee > 0) {
      aToken.approve(address(wethGateway), fee);
      wethGateway.withdrawETH(lendingPool, fee, feeTo);
      lastABalance = aToken.balanceOf(address(this));
      totalUnredeemedFee = 0;
    }
  }

  function wrap() external payable nonReentrant override {
    uint256 underlyingAmount = msg.value;
    require(underlyingAmount > 0, "underlyingAmount cannot be 0");
    uint256 toMint = underlyingToDebt(underlyingAmount);
    totalUnredeemedFee = totalUnredeemedFee.add(pendingFee());
    wethGateway.depositETH{value: underlyingAmount}(lendingPool, address(this), 0);
    _mint(msg.sender, toMint);

    // Assign lastABalance after we have wrapped
    lastABalance = aToken.balanceOf(address(this));
  }

  function unwrap(uint256 debtAmount) external override {
    if (debtAmount <= 0) {
      return;
    }
    uint256 toReturn = debtToUnderlying(debtAmount);
    totalUnredeemedFee = totalUnredeemedFee.add(pendingFee());
    _burn(msg.sender, debtAmount);
    aToken.approve(address(wethGateway), toReturn);
    wethGateway.withdrawETH(lendingPool, toReturn, msg.sender);

    // Assign lastABalance after we have unwrapped
    lastABalance = aToken.balanceOf(address(this));
  }

  function underlyingBalanceOf(address owner) external view override returns (uint256) {
    return debtToUnderlying(balanceOf(owner));
  }
}
