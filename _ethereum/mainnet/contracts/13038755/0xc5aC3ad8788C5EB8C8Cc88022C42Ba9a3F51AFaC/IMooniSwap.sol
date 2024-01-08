pragma solidity 0.6.12;

interface IMooniSwap {
  function swap(
    address src,
    address dst,
    uint256 amount,
    uint256 minReturn,
    address referral
  ) external payable returns (uint256 result);

  function swapFor(
    address src,
    address dst,
    uint256 amount,
    uint256 minReturn,
    address referral,
    address payable receiver
  ) external payable returns (uint256 result);
}
