// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  function distributeDividends() public override payable {
    require(totalSupply() > 0,"dividened totalsupply error");
    if (msg.value > 0) {
      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user, uint256 amount) internal returns (uint256) {
    if (amount > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(amount);
      (bool success,) = user.call{value: amount}("");
      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(amount);
        return 0;
      }
      return amount;
    }
    return 0;
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}