// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.6;
pragma abicoder v2;

// import "./OracleLibrary.sol";
// import "./PoolAddress.sol";
import "./OracleLibrary.sol";
import "./PoolAddress.sol";
import "./IOracleUsd.sol";
import "./IVaultParameters.sol";
import "./IOracleRegistry.sol";

contract UniswapV3OracleGCD is IOracleUsd {

  struct QuoteParams {
    address quoteAsset;
    uint24 poolFee;
    uint32 twapPeriod;
  }

  mapping (address => QuoteParams) public quoteParams;

  // GCD Protocol Vault parameters
  // Ropsten: 0x24643a31abb6F06C451D2be5ED01D2f95571d14a
  // Goerli: 0x634cd07fce65a2f2930b55c7b1b20a97196d362f
  // Ethereum: 0x1c2a972841A64872178fC510CeE5C87301d91160
  IVaultParameters public constant vaultParameters = IVaultParameters(0x1c2a972841A64872178fC510CeE5C87301d91160);

  // Uniswap V3 factory - same on all chaons
  address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

  // wETH
  // Ropsten: 0xc778417E063141139Fce010982780140Aa0cD5Ab
  // Goerli: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
  // Ethereum: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  address public defaultQuoteAsset = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // 0.3%
  uint24 public constant defaultPoolFee = 3000;

  uint32 public defaultTWAPPeriod = 30 minutes;

  // GCD Protocol oracle registry
  // Ropsten: 0x6B5701e3c6Ae063c6cBf23000E146DaaFA6db6cF
  // Goerli: 0xC0B881e21eE1B847A659206C0214E3357788E88E
  // Ethereum: 0x2E9B7ce6124284Fb6Afe402A619278E92Ac8Cf6B
  IOracleRegistry public constant oracleRegistry = IOracleRegistry(0x2E9B7ce6124284Fb6Afe402A619278E92Ac8Cf6B);

  event QuoteParamsSet(address indexed baseAsset, QuoteParams quoteParams);
  event DefaultTWAPPeriodSet(uint32 twapPeriod);
  event DefaultQuoteAssetSet(address quoteAsset);

  modifier onlyManager() {
    require(vaultParameters.isManager(msg.sender), "UniswapV3Oracle: !manager");
    _;
  }

  function setQuoteParams(address baseAsset, QuoteParams calldata quoteP) external onlyManager {
    quoteParams[baseAsset] = quoteP;
    emit QuoteParamsSet(baseAsset, quoteP);
  }

  function setDefaultTWAPPeriod(uint32 twapPeriod) external onlyManager {
    defaultTWAPPeriod = twapPeriod;
    emit DefaultTWAPPeriodSet(twapPeriod);
  }

  function setDefaultQuoteAsset(address quoteAsset) external onlyManager {
    defaultQuoteAsset = quoteAsset;
    emit DefaultQuoteAssetSet(quoteAsset);
  }

  // returns Q112-encoded value
  // returned value 10**18 * 2**112 is $1
  function assetToUsd(address baseAsset, uint amount) external view override returns(uint) {
    if (amount == 0) return 0;

    require(amount <= type(uint128).max, "UniswapV3Oracle: amount overflow");

    QuoteParams memory quote = quoteParams[baseAsset];

    if (quote.quoteAsset == address(0)) {
      quote.quoteAsset = defaultQuoteAsset;
    }

    require(quote.quoteAsset != baseAsset, "UniswapV3Oracle: quote == base");

    if (quote.poolFee == 0) {
      quote.poolFee = defaultPoolFee;
    }

    if (quote.twapPeriod == 0) {
      quote.twapPeriod = defaultTWAPPeriod;
    }

    PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(baseAsset, quote.quoteAsset, quote.poolFee);
    address pool = PoolAddress.computeAddress(factory, poolKey);

    // (int24 twaTick, ) = OracleLibrary.consult(pool, quote.twapPeriod); // current UniV3 version
    int24 twaTick = OracleLibrary.consult(pool, quote.twapPeriod); // Old version - added here
    uint twaPrice = OracleLibrary.getQuoteAtTick(twaTick, uint128(amount), baseAsset, quote.quoteAsset);

    return getOracle(quote.quoteAsset).assetToUsd(quote.quoteAsset, twaPrice);
  }

  function getOracle(address asset) public view returns(IOracleUsd) {
    address oracle =  oracleRegistry.oracleByAsset(asset);
    require(oracle != address(0), "UniswapV3Oracle: quote asset oracle not found");
    return IOracleUsd(oracle);
  }
}
