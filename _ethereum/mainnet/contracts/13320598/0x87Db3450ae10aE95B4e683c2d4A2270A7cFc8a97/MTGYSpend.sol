// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * @title MTGYSpend
 * @dev Logic for spending $MTGY on products in the moontography ecosystem.
 */
contract MTGYSpend is Ownable {
  ERC20 private _mtgy;

  struct SpentInfo {
    uint256 timestamp;
    uint256 tokens;
  }

  address public constant burnWallet =
    0x000000000000000000000000000000000000dEaD;
  address public devWallet = 0x3A3ffF4dcFCB7a36dADc40521e575380485FA5B8;
  address public rewardsWallet = 0x87644cB97C1e2Cc676f278C88D0c4d56aC17e838;
  address public mtgyTokenAddy;

  SpentInfo[] public spentTimestamps;
  uint256 public totalSpent = 0;

  event Spend(address indexed owner, uint256 value);

  constructor(address _mtgyTokenAddy) {
    mtgyTokenAddy = _mtgyTokenAddy;
    _mtgy = ERC20(_mtgyTokenAddy);
  }

  function changeMtgyTokenAddy(address _mtgyAddy) external onlyOwner {
    mtgyTokenAddy = _mtgyAddy;
    _mtgy = ERC20(_mtgyAddy);
  }

  function changeDevWallet(address _newDevWallet) external onlyOwner {
    devWallet = _newDevWallet;
  }

  function changeRewardsWallet(address _newRewardsWallet) external onlyOwner {
    rewardsWallet = _newRewardsWallet;
  }

  function getSpentByTimestamp() external view returns (SpentInfo[] memory) {
    return spentTimestamps;
  }

  /**
   * spendOnProduct: used by a moontography product for a user to spend their tokens on usage of a product
   *   25% goes to dev wallet
   *   25% goes to rewards wallet for rewards
   *   50% burned
   */
  function spendOnProduct(uint256 _productCostTokens) external returns (bool) {
    totalSpent += _productCostTokens;
    spentTimestamps.push(
      SpentInfo({ timestamp: block.timestamp, tokens: _productCostTokens })
    );
    uint256 _half = _productCostTokens / uint256(2);
    uint256 _quarter = _half / uint256(2);

    // 50% burn
    _mtgy.transferFrom(msg.sender, burnWallet, _half);
    // 25% rewards wallet
    _mtgy.transferFrom(msg.sender, rewardsWallet, _quarter);
    // 25% dev wallet
    _mtgy.transferFrom(
      msg.sender,
      devWallet,
      _productCostTokens - _half - _quarter
    );
    emit Spend(msg.sender, _productCostTokens);
    return true;
  }
}
