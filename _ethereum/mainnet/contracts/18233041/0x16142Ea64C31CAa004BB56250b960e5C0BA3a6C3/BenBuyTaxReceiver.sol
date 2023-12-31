// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IERC165.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IBuyTaxReceiver.sol";
import "./IUniswapV2Router02.sol";

contract BenBuyTaxReceiver is Ownable, IBuyTaxReceiver, IERC165 {
  using SafeERC20 for IERC20;

  IUniswapV2Router02 public immutable router;
  address public immutable wNative;

  address public benV2;
  uint96 public minimumBenReachedBeforeSwap;

  error OnlyBen();

  modifier onlyBen() {
    if (msg.sender != benV2) {
      revert OnlyBen();
    }
    _;
  }

  constructor(IUniswapV2Router02 _router, address _wNative, uint96 _minimumBenReachedBeforeSwap) {
    router = _router;
    wNative = _wNative;
    minimumBenReachedBeforeSwap = _minimumBenReachedBeforeSwap;
  }

  function supportsInterface(bytes4 _interfaceId) public pure override returns (bool) {
    return _interfaceId == type(IBuyTaxReceiver).interfaceId;
  }

  function _swap(uint _minimumBenToSwapReached) private {
    uint256 balance = IERC20(benV2).balanceOf(address(this));
    if (balance > _minimumBenToSwapReached) {
      address[] memory path = new address[](2);
      path[0] = benV2;
      path[1] = wNative;

      router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        balance,
        0, // accept any amount of ETH output
        path,
        owner(),
        block.timestamp
      );
    }
  }

  function swapCallback() external override onlyBen {
    _swap(minimumBenReachedBeforeSwap);
  }

  function forceSwap() external onlyOwner {
    _swap(0);
  }

  function setBen(address _benV2) external onlyOwner {
    benV2 = _benV2;
    if (address(router) != address(0)) {
      IERC20(_benV2).approve(address(router), type(uint256).max);
    }
  }

  function recoverTokens(address _token) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }

  function setMinimumBenReachedBeforeSwap(uint96 _minimumBenReachedBeforeSwap) external onlyOwner {
    minimumBenReachedBeforeSwap = _minimumBenReachedBeforeSwap;
  }
}
