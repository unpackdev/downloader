// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

/// @notice Collect ETH or in an unlikely scenario of tokens being sent to this contract allow admin to rescue them
abstract contract Rescue is Ownable {

  using SafeERC20 for IERC20;

  function rescueEth(address payable _beneficiary) external onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, "amount");
    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success,) = _beneficiary.call{ value : amount}("");
    require(success, "send failed");
  }

  function rescueERC20(address _token, uint256 _amount, address _beneficiary) external onlyOwner {
    require(_amount > 0, "amount");
    IERC20(_token).safeTransfer(_beneficiary, _amount);
  }

  function rescueERC721(address _token, uint256 _tokenId, address _beneficiary) external onlyOwner {
    IERC721(_token).safeTransferFrom(address(this), _beneficiary, _tokenId);
  }
}
