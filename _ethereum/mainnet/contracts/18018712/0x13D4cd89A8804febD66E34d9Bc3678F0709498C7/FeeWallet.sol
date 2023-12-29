// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IFeeWallet.sol";
import "./IWstETH.sol";
import "./IERC20.sol";
import "./Ownable.sol";

// Wallet to hold protocol fees or redemption fees (stETH) from the Vault.
// Once called by the fee distributor, converts stETH to wstETH and sends to the fee distributor.
// Note: deploy two instances of this contract, one for protocol fees and one for redemption fees.
contract FeeWallet is IFeeWallet, Ownable {
  
  address public wstETH;
  address public stETH;
  mapping(address => bool) public feeDistributors;

  // for conveniency: a human readable name to distinguish between protocol fees and redemption fees wallet
  string public walletName;


  constructor(address _wstETH, string memory _walletName) {
    wstETH = _wstETH;
    stETH = IWstETH(_wstETH).stETH();
    walletName = _walletName;
  }

  function withdraw() external override onlyFeeDistributor returns (uint256) {
    // wrap stETH to wstETH and send to fee distributor
    uint256 stETHAmount = IERC20(stETH).balanceOf(address(this));
    if (stETHAmount == 0) {
      return 0;
    }
    IERC20(stETH).approve(wstETH, stETHAmount);
    uint256 wstETHAmount = IWstETH(wstETH).wrap(stETHAmount);

    IWstETH(wstETH).transfer(msg.sender, wstETHAmount);

    return wstETHAmount;
  }

  // in case of bugs from wstETH or other usecases, allow fee distributor to withdraw stETH without wrapping
  function withdrawRaw() external override onlyFeeDistributor returns (uint256) {
    uint256 stETHAmountBefore = IERC20(stETH).balanceOf(address(this));
    if (stETHAmountBefore == 0) {
      return 0;
    }
    IWstETH(stETH).transfer(msg.sender, stETHAmountBefore);
    uint256 stETHAmountAfter = IERC20(stETH).balanceOf(address(this));

    return stETHAmountBefore - stETHAmountAfter;
  }

  function feeToken() external view override returns (address) {
    return wstETH;
  }

  function feeTokenRaw() external view override returns (address) {
    return stETH;
  }

  function setFeeDistributor(address _feeDistributor, bool _isFeeDistributor) external onlyOwner {
    feeDistributors[_feeDistributor] = _isFeeDistributor;
  }

  modifier onlyFeeDistributor() {
    require(feeDistributors[msg.sender], "!fee distributor");
    _;
  }
}