// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./CRVStrategyStable.sol";
import "./PriceConvertor.sol";

/**
* Adds the mainnet addresses to the CRVStrategyStable
*/
contract CRVStrategyStableMainnet is CRVStrategyStable {

  // token addresses
  // y-addresses are taken from: https://docs.yearn.finance/yearn.finance/yearn-1
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public ydai = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);
  address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public yusdc = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);
  address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address constant public yusdt = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);
  address constant public tusd = address(0x0000000000085d4780B73119b644AE5ecd22b376);
  address constant public ytusd = address(0x73a052500105205d34Daf004eAb301916DA8190f);

  // pre-defined constant mapping: underlying -> y-token
  mapping(address => address) public yVaults;

  // yDAIyUSDCyUSDTyTUSD
  address constant public __ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

  // ycrvVault
  address constant public __ycrvVault = address(0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c);

  // protocols
  address constant public __curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);

  constructor(
    address _storage,
    address _underlying,
    address _bundle
  )
  CRVStrategyStable(_storage, _underlying, _bundle, __ycrvVault, address(0), 0,
    __ycrv,
    __curve,
    address(0)
  )
  public {
    yVaults[dai] = ydai;
    yVaults[usdc] = yusdc;
    yVaults[usdt] = yusdt;
    yVaults[tusd] = ytusd; 
    yVault = yVaults[underlying];
    require(yVault != address(0), "underlying not supported: yVault is not defined");
    if (_underlying == dai) {
      tokenIndex = TokenIndex.DAI;
    } else if (_underlying == usdc) {
      tokenIndex = TokenIndex.USDC;
    } else if (_underlying == usdt) {
      tokenIndex = TokenIndex.USDT;
    } else if (_underlying == tusd) {
      tokenIndex = TokenIndex.TUSD;
    } else {
      revert("What is this asset?");
    }
    convertor = address(new PriceConvertor());
    curvePriceCheckpoint = underlyingValueFromYCrv(ycrvUnit);
  }
}
