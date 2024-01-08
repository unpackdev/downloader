pragma solidity 0.7.3;

import "./AlphaStrategy.sol";

contract Strategy is AlphaStrategy {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58);
    address slpRewardPool = address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address onxXSushiFarmRewardPool = address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9);
    address stakedOnx = address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c);
    address onx = address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033);
    address xSushi = address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    address sushi = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      underlying,
      _vault,
      slpRewardPool, // master chef contract
      21,  // SLP Pool id
      onxXSushiFarmRewardPool,
      7,
      onx,
      stakedOnx,
      sushi,
      xSushi
    );
  }
}
