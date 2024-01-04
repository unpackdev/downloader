// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./ERC20MetadataStorage.sol";

import "./AutoRewardTokenStorage.sol";

/**
 * @title Fee-on-transfer token with frictionless distribution to holders
 * @author Nick Barry
 */
contract AutoRewardToken is ERC20 {
  using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

  uint private constant BP_DIVISOR = 10000;
  uint private constant REWARD_SCALAR = 1e36;

  constructor (
    string memory name,
    string memory symbol,
    uint supply,
    uint fee
  ) {
    require(fee <= BP_DIVISOR, 'AutoRewardToken: fee must not exceed 10000 bp');

    {
      ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();
      l.setName(name);
      l.setSymbol(symbol);
      l.setDecimals(18);
    }

    AutoRewardTokenStorage.layout().fee = fee;

    _mint(msg.sender, supply);
  }

  /**
   * @notice return network fee
   * @return fee in basis points
   */
  function getFee () external view returns (uint) {
    return AutoRewardTokenStorage.layout().fee;
  }

  /**
   * @inheritdoc ERC20Base
   */
  function balanceOf (
    address account
  ) override public view returns (uint) {
    return super.balanceOf(account) + rewardsOf(account);
  }

  /**
   * @notice get pending rewards pending distribution to given account
   * @param account owner of rewards
   * @return quantity of rewards
   */
  function rewardsOf (
    address account
  ) public view returns (uint) {
    AutoRewardTokenStorage.Layout storage l = AutoRewardTokenStorage.layout();
    return (
      super.balanceOf(account) * l.cumulativeRewardPerToken
      + l.rewardsReserved[account]
      - l.rewardsExcluded[account]
    ) / REWARD_SCALAR;
  }

  /**
   * @inheritdoc ERC20Base
   * @notice override of _transfer function to include call to _afterTokenTransfer
   */
  function _transfer (
    address sender,
    address recipient,
    uint amount
  ) override internal {
    super._transfer(sender, recipient, amount);
    _afterTokenTransfer(sender, recipient, amount);
  }

  /**
   * @notice ERC20 hook: apply fees and distribute rewards on transfer
   * @inheritdoc ERC20Base
   */
  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) override internal {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0) || to == address(0)) {
      return;
    }

    AutoRewardTokenStorage.Layout storage l = AutoRewardTokenStorage.layout();

    uint fee = amount * l.fee / BP_DIVISOR;

    // update internal balances to include rewards

    uint rewardsFrom = rewardsOf(from);
    ERC20BaseStorage.layout().balances[from] += rewardsFrom;
    delete l.rewardsReserved[from];

    uint rewardsTo = rewardsOf(to);    
    ERC20BaseStorage.layout().balances[to] += rewardsTo;
    
    delete l.rewardsReserved[to];

    // track exclusions from future rewards

    l.rewardsExcluded[from] = (super.balanceOf(from) - amount) * l.cumulativeRewardPerToken;
    l.rewardsExcluded[to] = (super.balanceOf(to) + amount - fee) * l.cumulativeRewardPerToken;
    
    // distribute rewards globally

    l.cumulativeRewardPerToken += (fee * REWARD_SCALAR) / (totalSupply() - fee);

    // simulate transfers
    emit Transfer(from, address(0), fee);
    emit Transfer(address(0), from, rewardsFrom);
    emit Transfer(address(0), to, rewardsTo);
  }

  /**
   * @notice ERC20 hook: remove fee from recipient
   * @param to recipient address
   * @param amount quantity transferred
   */
  function _afterTokenTransfer (
    address,
    address to,
    uint amount
  ) private {
    _burnFee(to, amount * AutoRewardTokenStorage.layout().fee / BP_DIVISOR);

  }
}
