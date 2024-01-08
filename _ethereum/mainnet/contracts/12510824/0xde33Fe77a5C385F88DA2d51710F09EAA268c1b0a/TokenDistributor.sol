//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./EthAddressLib.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/// @title TokenDistributor
/// @author Aito
/// @dev Receives tokens and manages the distribution amongst receivers
contract TokenDistributor is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Distribution {
    address[] receivers;
    uint256[] percentages;
  }

  event DistributionUpdated(address[] receivers, uint256[] percentages);
  event Distributed(address receiver, uint256 percentage, uint256 amount);

  /// @dev Defines how tokens and ETH are distributed on each call to .distribute()
  Distribution private distribution;

  /// @dev Instead of using 100 for percentages, higher base to have more precision in the distribution
  uint256 public constant DISTRIBUTION_BASE = 10000;

  constructor(address[] memory _receivers, uint256[] memory _percentages) {
    _setTokenDistribution(_receivers, _percentages);
  }

  /// @dev Allows the owner to change the receivers and their percentages
  /// @param _receivers Array of addresses receiving a percentage of the distribution, both user addresses
  ///   or contracts
  /// @param _percentages Array of percentages each _receivers member will get
  function setTokenDistribution(address[] memory _receivers, uint256[] memory _percentages)
    external
    onlyOwner
  {
    _setTokenDistribution(_receivers, _percentages);
  }

  /// @dev Distributes the whole balance of a list of _tokens balances in this contract
  /// @param _tokens list of ERC20 tokens to distribute
  function distribute(IERC20[] memory _tokens) external {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _balanceToDistribute =
        (address(_tokens[i]) != EthAddressLib.ethAddress())
          ? _tokens[i].balanceOf(address(this))
          : address(this).balance;
      if (_balanceToDistribute <= 0) {
        continue;
      }

      _distributeTokenWithAmount(_tokens[i], _balanceToDistribute);
    }
  }

  /// @dev Distributes specific amounts of a list of _tokens
  /// @param _tokens list of ERC20 tokens to distribute
  /// @param _amounts list of amounts to distribute per token
  function distributeWithAmounts(IERC20[] memory _tokens, uint256[] memory _amounts) public {
    for (uint256 i = 0; i < _tokens.length; i++) {
      _distributeTokenWithAmount(_tokens[i], _amounts[i]);
    }
  }

  /// @dev Distributes specific total balance's percentages of a list of _tokens
  /// @param _tokens list of ERC20 tokens to distribute
  /// @param _percentages list of percentages to distribute per token
  function distributeWithPercentages(IERC20[] memory _tokens, uint256[] memory _percentages)
    external
  {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 _amountToDistribute =
        (address(_tokens[i]) != EthAddressLib.ethAddress())
          ? _tokens[i].balanceOf(address(this)).mul(_percentages[i]).div(100)
          : address(this).balance.mul(_percentages[i]).div(100);
      if (_amountToDistribute <= 0) {
        continue;
      }

      _distributeTokenWithAmount(_tokens[i], _amountToDistribute);
    }
  }

  /// @dev Returns the receivers and percentages of the contract Distribution
  /// @return receivers array of addresses and percentages array on uints
  function getDistribution() external view returns (Distribution memory) {
    return distribution;
  }

  receive() external payable {}

  function _setTokenDistribution(address[] memory _receivers, uint256[] memory _percentages)
    internal
  {
    require(_receivers.length == _percentages.length, 'Array lengths should be equal');

    uint256 sumPercentages;
    for (uint256 i = 0; i < _percentages.length; i++) {
      sumPercentages += _percentages[i];
    }
    require(sumPercentages == DISTRIBUTION_BASE, 'INVALID_%_SUM');

    distribution = Distribution({receivers: _receivers, percentages: _percentages});
    emit DistributionUpdated(_receivers, _percentages);
  }

  function _distributeTokenWithAmount(IERC20 _token, uint256 _amountToDistribute) internal {
    address _tokenAddress = address(_token);
    Distribution memory _distribution = distribution;
    for (uint256 j = 0; j < _distribution.receivers.length; j++) {
      uint256 _amount =
        _amountToDistribute.mul(_distribution.percentages[j]).div(DISTRIBUTION_BASE);

      //avoid transfers/burns of 0 tokens
      if (_amount == 0) {
        continue;
      }

      if (_tokenAddress != EthAddressLib.ethAddress()) {
        _token.safeTransfer(_distribution.receivers[j], _amount);
      } else {
        //solium-disable-next-line
        (bool _success, ) = _distribution.receivers[j].call{value: _amount}('');
        require(_success, 'Reverted ETH transfer');
      }
      emit Distributed(_distribution.receivers[j], _distribution.percentages[j], _amount);
    }
  }
}
