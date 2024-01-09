// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "UpgradeableBeacon.sol";

import "IPairFactory.sol";
import "ILendingController.sol";
import "ILendingPair.sol";

import "SafeOwnable.sol";
import "AddressLibrary.sol";
import "BeaconProxyPayable.sol";

import "LendingPair.sol";

contract PairFactory is IPairFactory, SafeOwnable {

  using AddressLibrary for address;

  UpgradeableBeacon public immutable lendingPairMaster;
  address public immutable lpTokenMaster;
  address public immutable uniV3Helper;
  address public immutable feeRecipient;
  ILendingController public immutable lendingController;

  mapping(address => mapping(address => address)) public override pairByTokens;

  event PairCreated(address indexed pair, address indexed tokenA, address indexed tokenB);

  constructor(
    address _lendingPairMaster,
    address _lpTokenMaster,
    address _uniV3Helper,
    address _feeRecipient,
    ILendingController _lendingController
  ) {

    require(_lendingPairMaster.isContract(), 'PairFactory: _lendingPairMaster must be a contract');
    require(_lpTokenMaster.isContract(),     'PairFactory: _lpTokenMaster must be a contract');
    require(_uniV3Helper.isContract(),       'PairFactory: _uniV3Helper must be a contract');
    require(_feeRecipient.isContract(),      'PairFactory: _feeRecipient must be a contract');
    require(address(_lendingController).isContract(), 'PairFactory: _lendingController must be a contract');

    lendingPairMaster = UpgradeableBeacon(_lendingPairMaster);
    lpTokenMaster     = _lpTokenMaster;
    uniV3Helper       = _uniV3Helper;
    feeRecipient      = _feeRecipient;
    lendingController = _lendingController;
  }

  function createPair(
    address _token0,
    address _token1
  ) external returns(address) {

    require(_token0 != _token1, 'PairFactory: duplicate tokens');
    require(_token0 != address(0) && _token1 != address(0), 'PairFactory: zero address');
    require(pairByTokens[_token0][_token1] == address(0), 'PairFactory: already exists');

    (address tokenA, address tokenB) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);

    require(
      lendingController.tokenSupported(tokenA) && lendingController.tokenSupported(tokenB),
      'PairFactory: token not supported'
    );

    address lendingPair = address(new BeaconProxyPayable(address(lendingPairMaster), ""));

    ILendingPair(lendingPair).initialize(
      lpTokenMaster,
      address(lendingController),
      uniV3Helper,
      feeRecipient,
      tokenA,
      tokenB
    );

    pairByTokens[tokenA][tokenB] = lendingPair;
    pairByTokens[tokenB][tokenA] = lendingPair;

    emit PairCreated(lendingPair, tokenA, tokenB);

    return lendingPair;
  }
}
