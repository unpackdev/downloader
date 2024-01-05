// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "./Utils.sol";
import "./PermissionAdmin.sol";
import "./PermissionOperators.sol";
import "./IERC20Ext.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./IPool.sol";


/**
* Pool contract containing all tokens which whitelisted strategies can withdraw funds from
*/
contract Pool is IPool, PermissionAdmin, PermissionOperators, Utils {
  using SafeERC20 for IERC20Ext;
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private _authorizedStrategies;
  bool private _isPaused;

  constructor(address admin, address[] memory strategies) PermissionAdmin(admin) {
    for(uint256 i = 0; i < strategies.length; i++) {
      _authorizeStrategy(strategies[i]);
    }
    _isPaused = false;
  }

  receive() external payable {}

  function authorizeStrategies(address[] calldata strategies)
    external override onlyAdmin
  {
    for(uint256 i = 0; i < strategies.length; i++) {
      _authorizeStrategy(strategies[i]);
    }
  }

  function unauthorizeStrategies(address[] calldata strategies)
    external override onlyAdmin
  {
    for(uint256 i = 0; i < strategies.length; i++) {
      _unauthorizeStrategy(strategies[i]);
    }
  }

  function pause() external override onlyOperator {
    _isPaused = true;
    emit Paused(msg.sender);
  }

  function unpause() external override onlyAdmin {
    _isPaused = false;
    emit Unpaused(msg.sender);
  }

  function withdrawFunds(
    IERC20Ext[] calldata tokens,
    uint256[] calldata amounts,
    address payable recipient
  ) external override {
    require(!_isPaused, 'only when not paused');
    require(isAuthorizedStrategy(msg.sender), 'not authorized');
    require(tokens.length == amounts.length, 'invalid lengths');
    for(uint256 i = 0; i < tokens.length; i++) {
      _transferToken(tokens[i], amounts[i], recipient);
    }
  }

  function isPaused() external view override returns (bool) {
    return _isPaused;
  }

  function getAuthorizedStrategiesLength()
    external view override returns (uint256)
  {
    return _authorizedStrategies.length();
  }

  function getAuthorizedStrategyAt(uint256 index)
    external view override returns (address)
  {
    return _authorizedStrategies.at(index);
  }

  function getAllAuthorizedStrategies()
    external view override returns (address[] memory strategies)
  {
    uint256 length = _authorizedStrategies.length();
    strategies = new address[](length);
    for(uint256 i = 0; i < length; i++) {
      strategies[i] = _authorizedStrategies.at(i);
    }
  }

  function isAuthorizedStrategy(address strategy)
    public view override returns (bool)
  {
    return _authorizedStrategies.contains(strategy);
  }

  function _authorizeStrategy(address strategy) internal {
    require(strategy != address(0), 'invalid strategy');
    require(!isAuthorizedStrategy(strategy), 'only unauthorized strategy');
    require(_authorizedStrategies.add(strategy), 'unable to add new strategy');
    emit AuthorizedStrategy(strategy);
  }

  function _unauthorizeStrategy(address _strategy) internal {
    require(_strategy != address(0), 'invalid strategy');
    require(isAuthorizedStrategy(_strategy), 'only authorized strategy');
    require(_authorizedStrategies.remove(_strategy), 'unable to remove strategy');
    emit UnauthorizedStrategy(_strategy);
  }

  function _transferToken(
    IERC20Ext _token,
    uint256 _amount,
    address payable _recipient
  ) internal {
    if (_token == ETH_TOKEN_ADDRESS) {
      (bool success, ) = _recipient.call{ value: _amount }('');
        require(success, 'transfer eth failed');
    } else {
      _token.safeTransfer(_recipient, _amount);
    }
    emit WithdrawToken(_token, msg.sender, _recipient, _amount);
  }
}
