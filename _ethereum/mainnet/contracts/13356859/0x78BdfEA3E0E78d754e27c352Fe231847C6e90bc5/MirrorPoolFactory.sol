// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";
import "./ISetTokenCreator.sol";

contract MirrorPoolFactory is OwnableUpgradeable {
  ISetTokenCreator public setTokenCreator;

  /**
   * @dev has to be updated after each `createPool`
   */
  mapping(address => address) private pools;

  struct TokenSetInfo {
    address[] tokens;
    int256[] units;
    address[] modules;
    string name;
    string symbol;
  }

  /**
   *   event to notify about new pool creation
   *   @dev has to be emited in `createPool` func
   *   @param manager -- address of manager
   *   @param atrader -- address of pool's atrader
   *   @param mirrorPool -- address of mirror pool (token set)
   */
  event NewPoolCreated(
    address indexed manager,
    address indexed atrader,
    address indexed mirrorPool
  );

  function initialize(address _setTokenCreator) external initializer {
    setTokenCreator = ISetTokenCreator(_setTokenCreator);
    __Ownable_init();
  }

  /**
   *    method to create new mirror pool contract
   *    @dev verify that pool does not exists already
   *    @dev add new pool to `pools` mapping

   *    @param _alphaTrader -- address of alpha trader to bind pool with
   *    @param _info -- TokenSetInfo
   */
  function createPool(address _alphaTrader, TokenSetInfo calldata _info)
    external
    onlyOwner
  {
    address manager = address(msg.sender);
    address newPool = setTokenCreator.create(
      _info.tokens,
      _info.units,
      _info.modules,
      manager,
      _info.name,
      _info.symbol
    );
    pools[_alphaTrader] = newPool;

    emit NewPoolCreated(manager, _alphaTrader, newPool);
  }
}
