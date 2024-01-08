pragma solidity 0.7.6;

import "./SafeERC20.sol";

contract Airdrop {
  using SafeERC20 for IERC20;

  function airdrop(
    address _token,
    address[] calldata recipients,
    uint256[] calldata values
  ) public {
    IERC20 token = IERC20(_token);
    for (uint256 i = 0; i < recipients.length; i++) {
      token.safeTransferFrom(msg.sender, recipients[i], values[i]);
    }
  }
}
