//contracts/wallet/ReleaseController.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ReleaseController is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public token;
  address public beneficiary;
  uint256 public blockPerPeriod;
  uint256 public releaseAmount; // total amount to distribute
  uint256 public releaseAmountPerPeriod;
  uint256 public released; // total distributed amount
  uint256 public nextReleaseBlock;
  uint256 public gracePeriodBlock;

  event ReleaseToken(address indexed beneficiary, uint256 releaseTokenAmount, uint256 nextReleaseBlock);

  constructor(
    IERC20 _token,
    address _beneficiary,
    uint256 _blockPerDay, // BSC 28800, ETH 6500
    uint256 _releaseAmount,
    uint256 _releasePeriod,
    uint256 _releaseFrequency, // monthly(30), daily(1)
    uint256 _nextReleaseBlock,
    uint256 _gracePeriod // days
  ) {
    token = _token;
    beneficiary = _beneficiary;
    blockPerPeriod = _blockPerDay.mul(_releaseFrequency);
    releaseAmount = _releaseAmount;
    releaseAmountPerPeriod = _releaseAmount.div(_releasePeriod);
    nextReleaseBlock = _nextReleaseBlock;
    gracePeriodBlock = _nextReleaseBlock.add((blockPerPeriod.mul(_releasePeriod)).add(_blockPerDay.mul(_gracePeriod)));
  }

  modifier onlyBeneficiary() {
    require(beneficiary == _msgSender(), "Ownable: caller is not the beneficiary");
    _;
  }

  function releaseToken() external onlyBeneficiary {
    require(block.number >= nextReleaseBlock, "releaseToken: unable to claim token due to it is in a lock period");

    if (releaseAmount > released) {
      uint256 periodTimes = _getPeriodTimes();
      require(periodTimes > 0, "releaseToken: unable to claim token due to it is not reach its distribution timeframe");

      uint256 tokenAmount = releaseAmountPerPeriod.mul(periodTimes);
      uint256 walletBalance = releaseAmount.sub(released);
      uint256 releaseTokenAmount = tokenAmount;

      if (walletBalance <= tokenAmount) {
        releaseTokenAmount = walletBalance;
      }

      released = released.add(releaseTokenAmount);
      nextReleaseBlock = nextReleaseBlock.add(blockPerPeriod.mul(periodTimes));

      token.safeTransfer(beneficiary, releaseTokenAmount);

      emit ReleaseToken(beneficiary, releaseTokenAmount, nextReleaseBlock);
    }
  }

  function _getPeriodTimes() internal returns (uint256) {
    uint256 blocks = block.number.sub(nextReleaseBlock);
    return blocks.div(blockPerPeriod);
  }

  function transferExceedAmount(address _to) external onlyOwner {
    require(_to != address(0), "ReleaseController: cannot transfer exceed amount to zero address");
    uint256 totalBalance = token.balanceOf(address(this)).add(released);
    require(totalBalance > releaseAmount, "ReleaseController: balance is not exceed");
    token.safeTransfer(_to, totalBalance.sub(releaseAmount));
  }

  function recoverAmountExceedGracePeriod(address _to) external onlyOwner {
    require(block.number >= gracePeriodBlock, "ReleaseController: not exceed grace period yet");
    require(_to != address(0), "ReleaseController: cannot recover amount to zero address");
    token.safeTransfer(_to, token.balanceOf(address(this)));
  }
}
