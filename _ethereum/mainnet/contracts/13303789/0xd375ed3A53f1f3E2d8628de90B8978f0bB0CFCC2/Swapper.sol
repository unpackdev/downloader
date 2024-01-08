// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IKAE.sol";
import "./IYLD.sol";


contract Swapper is ReentrancyGuard
{
  using SafeERC20 for IERC20;


  address private constant _YLD = 0xDcB01cc464238396E213a6fDd933E36796eAfF9f;
  address private constant _KAE = 0x65Def5029A0e7591e46B38742bFEdd1Fb7b24436;

  uint256 private immutable _DEADLINE;


  event Swap (address indexed account, uint256 amount);


  constructor ()
  {
    _DEADLINE = block.timestamp + 45 days;
  }

  function getDeadline () external view returns (uint256)
  {
    return _DEADLINE;
  }

  function swap () public nonReentrant
  {
    require(block.timestamp < _DEADLINE, "> deadline");

    uint256 balance = IERC20(_YLD).balanceOf(msg.sender);

    require(balance > 0, "!valid balance");

    IERC20(_YLD).safeTransferFrom(msg.sender, address(this), balance);

    IYLD(_YLD).burn(balance);
    IKAE(_KAE).mint(msg.sender, balance);


    emit Swap(msg.sender, balance);
  }
}
