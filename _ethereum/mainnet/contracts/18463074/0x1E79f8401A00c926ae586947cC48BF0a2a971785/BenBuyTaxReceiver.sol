// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IERC165.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IBuyTaxReceiver.sol";
import "./IUniswapV2Router02.sol";

/**
 * @title BEN Buy Tax Receiver
 * @author Ben Coin Collective
 * @notice This contract handles the receipt of the BEN buy tax.
 */
contract BenBuyTaxReceiver is Ownable, IBuyTaxReceiver, IERC165 {
  using SafeERC20 for IERC20;

  IUniswapV2Router02 public immutable router;
  address public immutable wNative;

  address public benV2;
  uint96 public minimumBenReachedBeforeSwap;

  error OnlyBen();
  error ApproveFailed();

  modifier onlyBen() {
    if (msg.sender != benV2) {
      revert OnlyBen();
    }
    _;
  }

  /**
   * @param _router The UniswapV2 router
   * @param _benV2 The BenV2 address
   * @param _wNative The wrapped native token (e.g., WETH)
   * @param _minimumBenReachedBeforeSwap The minimum amount of BEN required before swapping
   */
  constructor(IUniswapV2Router02 _router, address _benV2, address _wNative, uint96 _minimumBenReachedBeforeSwap) {
    // Check the approval first
    if (!IERC20(_benV2).approve(address(_router), type(uint256).max)) {
      revert ApproveFailed();
    }
    router = _router;
    benV2 = _benV2;
    wNative = _wNative;
    minimumBenReachedBeforeSwap = _minimumBenReachedBeforeSwap;
  }

  /**
   * @param _interfaceId The interface ID
   * @return True if the contract supports the given interface ID, otherwise false
   */
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

  /**
   * @notice Called by the BEN token contract when a sell is made, swapping any BEN for WETH inside this contract
   */
  function swapCallback() external override onlyBen {
    _swap(minimumBenReachedBeforeSwap);
  }

  /**
   * @notice Swaps any BEN for WETH inside this contract. There is no minimum, so trading dust amounts may fail.
   * @dev Only callable by the owner
   */
  function forceSwap() external onlyOwner {
    _swap(0);
  }

  /**
   * @notice Recovers any tokens sent to this contract
   * @param _token The token to recover
   * @dev Only callable by the owner
   */
  function recoverTokens(address _token) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }

  /**
   * @notice Sets the minimum amount of BEN required in this contract before swapping
   * @param _minimumBenReachedBeforeSwap The minimum amount of BEN required before swapping
   * @dev Only callable by the owner
   */
  function setMinimumBenReachedBeforeSwap(uint96 _minimumBenReachedBeforeSwap) external onlyOwner {
    minimumBenReachedBeforeSwap = _minimumBenReachedBeforeSwap;
  }
}
