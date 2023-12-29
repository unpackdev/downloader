// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";

contract UnclSwap is Ownable2Step, ReentrancyGuard {

  struct Rate {
    uint256 uncx;
    uint256 uncl;
  }

  struct Tokens {
    IERC20 uncx;
    IERC20 uncl;
  }

  Rate public RATE;
  Tokens public TOKENS;
  bool public SWAP_ENABLED;

  event onSwap(address sender, uint256 amountUnclIn, uint256 amountUncxOut);

  constructor(IERC20 _uncx, IERC20 _uncl) {
    TOKENS.uncx = _uncx;
    TOKENS.uncl = _uncl;
    SWAP_ENABLED = true;
    RATE.uncx = 1e18;
    RATE.uncl = 70e18;
  }

  function swapTokens (uint256 _amount) external nonReentrant {
    require(SWAP_ENABLED, 'SWAP DISABLED');
    uint256 uncxAmountOut = getAmountOut(_amount);
    require(uncxAmountOut > 0, "ZERO AMOUNT OUT");
    TransferHelper.safeTransferFrom(address(TOKENS.uncl), msg.sender, address(this), _amount);
    TransferHelper.safeTransfer(address(TOKENS.uncx), msg.sender, uncxAmountOut);
    emit onSwap(msg.sender, _amount, uncxAmountOut);
  }

  function getAmountOut (uint256 _amount) public view returns (uint256 amountOut) {
    amountOut = _amount * RATE.uncx / RATE.uncl;
  }

  function enableSwap (bool _enabled) external onlyOwner {
    SWAP_ENABLED = _enabled;
  }

  function editRate (uint256 _uncxAmount, uint256 _unclAmount) external onlyOwner {
    RATE.uncx = _uncxAmount;
    RATE.uncl = _unclAmount;
  }

  /**
  * @dev Allows admin to remove any ERC20's sent to the contract
  */
  function adminRefundERC20 (address _token, address _receiver, uint _amount) external onlyOwner {
    TransferHelper.safeTransfer(_token, _receiver, _amount);
  }

}