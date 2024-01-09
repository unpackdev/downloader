// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract RoyaltyDistribution is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 constant shareOfRoyalty1 = 9900;
  uint256 constant shareOfRoyalty2 = 100;

  address payable public addr1;
  address payable public addr2;

  constructor(address payable _one, address payable _two) {
    require(_one != address(0));
    require(_two != address(0));

    addr1 = _one;
    addr2 = _two;
  }

  function changeOne(address payable _new) external onlyOwner {
    require(_new != address(0));

    addr1 = _new;
  }

  function changeTwo(address payable _new) external onlyOwner {
    require(_new != address(0));

    addr2 = _new;
  }

  receive() external payable {}

  function claimEther() external nonReentrant {
    uint256 total = address(this).balance;
    require(total > 0, "Nothing to claim");

    addr1.transfer((total * shareOfRoyalty1) / 10000);
    addr2.transfer((total * shareOfRoyalty2) / 10000);
  }

  function claimToken(address token) external nonReentrant {
    IERC20 claimableToken = IERC20(token);
    uint256 total = claimableToken.balanceOf(address(this));
    require(total > 0, "Nothing to claim");
    claimableToken.safeTransfer(addr1, (total * shareOfRoyalty1) / 10000);
    claimableToken.safeTransfer(addr2, (total * shareOfRoyalty2) / 10000);
  }
}
