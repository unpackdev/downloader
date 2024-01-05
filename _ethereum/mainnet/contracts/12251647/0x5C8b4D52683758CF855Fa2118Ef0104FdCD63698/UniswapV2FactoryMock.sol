// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./UniswapV2Factory.sol";
import "./UniswapV2PairMock.sol";

/**
 * @notice Mock adaptation of UniswapV2Factory
 */
contract UniswapV2FactoryMock is UniswapV2Factory {
  address public override feeTo;
  address public override feeToSetter;

  mapping(address => mapping(address => address)) public override getPair;
  address[] public override allPairs;

  constructor(
    address _feeToSetter
  ) {
    feeToSetter = _feeToSetter;
  }

  function allPairsLength()
    external
    view
    override
    returns (
      uint
    )
  {
    return allPairs.length;
  }

  function createPair(
    address tokenA,
    address tokenB
  )
    external
    override
    returns (
      address pair
    )
  {
    require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
    require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
    
    UniswapV2PairMock newPair = new UniswapV2PairMock(token0, token1);
    pair = address(newPair);

    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair; // populate mapping in the reverse direction
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }

  function setFeeTo(
    address _feeTo
  )
    external
    override
  {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeTo = _feeTo;
  }

  function setFeeToSetter(
    address _feeToSetter
  )
    external
    override
  {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeToSetter = _feeToSetter;
  }
}
