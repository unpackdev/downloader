// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

import "./BurnAddress.sol";
import "./StakeToken.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract TokenSwap is Ownable, Pausable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  uint256 public swapFromQuantity;
  uint256 public swapToQuantity;


  // the burn address is the address of a contract with no functions
  // this makes the swap contract usable with a token contract that does not allow transferring to the 0x0 address
  // it also guarantees that no one has the private key to the burn address
  address public burnAddress;
  IERC20 public fromToken;
  StakeToken public toToken;

  event Swap(
    address indexed sender,
    uint256 sentAmount,
    uint256 receivedAmount
  );

  /**
  * @param _swapFromQuantity: denominator in the swapping fraction (e.g. 30 NewTokens for 100 OldTokens)
  * @param _swapToQuantity: numerator in the swapping fraction, respectively
  * @param _fromTokenAddress: source token, the one being swapped
  * @param _toTokenAddress: destination token, the one we mint and give out
  */
  constructor(
    uint256 _swapFromQuantity,
    uint256 _swapToQuantity,
    address _fromTokenAddress,
    address _toTokenAddress
  ) {
    require(_swapFromQuantity > 0, "TokenSwap: Trying to set zero numerator");
    require(_swapToQuantity > 0, "TokenSwap: Trying to set zero denominator");
    require(_fromTokenAddress != address(0), "TokenSwap: Trying to set zero address source token");
    require(_toTokenAddress != address(0), "TokenSwap: Trying to set zero address destination token");

    swapFromQuantity = _swapFromQuantity;
    swapToQuantity = _swapToQuantity;
    burnAddress = address(new BurnAddress());
    fromToken = IERC20(_fromTokenAddress);
    toToken = StakeToken(_toTokenAddress);
  }

  /**
  * Performs the swap for the given amount of source tokens. Uses pull, so needs allowance
  *
  * @param fromAmount: how many tokens the contract will attempt to pull
  */
  function swap(uint256 fromAmount) public whenNotPaused {
    require(fromAmount > 0, "TokenSwap: Amount of swapped tokens cannot be zero");
    fromToken.safeTransferFrom(msg.sender, burnAddress, fromAmount);
    uint256 exchangeAmount = fromAmount.mul(swapToQuantity).div(swapFromQuantity);
    toToken.mint(msg.sender, exchangeAmount);
    emit Swap(msg.sender, fromAmount, exchangeAmount);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
  * View for the source token
  */
  function fromTokenAddress() public view returns (address) {
    return address(fromToken);
  }

  /**
  * View for the exchange ratio (returns numerator and denominator)
  */
  function swapRatio() public view returns (uint256, uint256) {
    return (swapFromQuantity, swapToQuantity);
  }

  /**
  * View for the destination token
  */
  function toTokenAddress() public view returns (address) {
    return address(toToken);
  }
}
