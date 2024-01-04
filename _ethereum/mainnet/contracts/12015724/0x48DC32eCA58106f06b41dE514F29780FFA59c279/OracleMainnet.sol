import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ICurvePool.sol";
import "./ICurveRegistry.sol";
import "./IMooniFactory.sol";
import "./IMooniswap.sol";
import "./Governable.sol";

pragma solidity 0.6.12;

contract OracleMainnet is Governable {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  //Addresses for factories and registries for different DEX platforms. Functions will be added to allow to alter these when needed.
  address public uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address public sushiswapFactoryAddress = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
  address public curveRegistryAddress = 0x7D86446dDb609eD0F5f8684AcF30380a356b2B4c;
  address public oneInchFactoryAddress = 0xbAF9A5d4b0052359326A6CDAb54BABAa3a3A9643;
  uint256 public precisionDecimals = 18;

  IUniswapV2Factory uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
  IUniswapV2Factory sushiswapFactory = IUniswapV2Factory(sushiswapFactoryAddress);
  ICurveRegistry curveRegistry = ICurveRegistry(curveRegistryAddress);
  IMooniFactory oneInchFactory = IMooniFactory(oneInchFactoryAddress);

  //Key tokens are used to find liquidity for any given token on Uni, Sushi and Curve.
  address[] public keyTokens = [
  0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, //USDC
  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, //WETH
  0x6B175474E89094C44Da98b954EedeAC495271d0F, //DAI
  0xdAC17F958D2ee523a2206206994597C13D831ec7, //USDT
  0xa47c8bf37f92aBed4A126BDA807A7b7498661acD, //UST
  0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, //WBTC
  0xdB25f211AB05b1c97D595516F45794528a807ad8, //EURS
  0x514910771AF9Ca656af840dff83E8264EcF986CA  //LINK
  ];
  //Pricing tokens are Key tokens with good liquidity with the defined output token on Uniswap.
  address[] public pricingTokens = [
  0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, //USDC
  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, //WETH
  0x6B175474E89094C44Da98b954EedeAC495271d0F, //DAI
  0xdAC17F958D2ee523a2206206994597C13D831ec7, //USDT
  0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, //WBTC
  0xdB25f211AB05b1c97D595516F45794528a807ad8  //EURS
  ];
  //The defined output token is the unit in which prices of input tokens are given.
  address public definedOutputToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC

  //Below are addresses of LP tokens for which it is known that the get_underlying functions of Curve Registry do not work because of errors in the Curve contract.
  //The exceptions are split. In the first exception the get_underlying_coins is called with get_balances.
  //In the second exception get_coins and get_balances are called.
  address[] public curveExceptionList0 = [
  0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900,
  0x02d341CcB60fAaf662bC0554d13778015d1b285C
  ];
  address[] public curveExceptionList1 = [
  0x49849C98ae39Fff122806C06791Fa73784FB3675,
  0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3,
  0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf
  ];

  modifier validKeyToken(address keyToken){
      require(checkKeyToken(keyToken), "Not a Key Token");
      _;
  }
  modifier validPricingToken(address pricingToken){
      require(checkPricingToken(pricingToken), "Not a Pricing Token");
      _;
  }
  modifier validException(address exception){
      (bool check0, bool check1) = checkCurveException(exception);
      require(check0 || check1, "Not an exception");
      _;
  }

  event FactoryChanged(address newFactory, address oldFactory);
  event RegistryChanged(address newRegistry, address oldRegistry);
  event KeyTokenAdded(address newKeyToken);
  event PricingTokenAdded(address newPricingToken);
  event KeyTokenRemoved(address keyToken);
  event PricingTokenRemoved(address pricingToken);
  event DefinedOutuptChanged(address newOutputToken, address oldOutputToken);
  event CurveExceptionAdded(address newException, uint256 exceptionList);
  event CurveExceptionRemoved(address oldException, uint256 exceptionList);

  constructor(address _storage)
  Governable(_storage) public {}

  function changeUniFactory(address newFactory) external onlyGovernance {
    address oldFactory = uniswapFactoryAddress;
    uniswapFactoryAddress = newFactory;
    uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
    emit FactoryChanged(newFactory, oldFactory);
  }
  function changeSushiFactory(address newFactory) external onlyGovernance {
    address oldFactory = sushiswapFactoryAddress;
    sushiswapFactoryAddress = newFactory;
    sushiswapFactory = IUniswapV2Factory(sushiswapFactoryAddress);
    emit FactoryChanged(newFactory, oldFactory);
  }
  function changeCurveRegistry(address newRegistry) external onlyGovernance {
    address oldRegistry = curveRegistryAddress;
    curveRegistryAddress = newRegistry;
    curveRegistry = ICurveRegistry(curveRegistryAddress);
    emit RegistryChanged(newRegistry, oldRegistry);
  }
  function changeOneInchFactory(address newFactory) external onlyGovernance {
    address oldFactory = oneInchFactoryAddress;
    oneInchFactoryAddress = newFactory;
    oneInchFactory = IMooniFactory(oneInchFactoryAddress);
    emit FactoryChanged(newFactory, oldFactory);
  }

  function addKeyToken(address newToken) external onlyGovernance {
    require((checkKeyToken(newToken)==false), "Already a key token");
    keyTokens.push(newToken);
    emit KeyTokenAdded(newToken);
  }
  function addPricingToken(address newToken) public onlyGovernance validKeyToken(newToken) {
    require((checkPricingToken(newToken)==false), "Already a pricing token");
    pricingTokens.push(newToken);
    emit PricingTokenAdded(newToken);
  }

  function removeKeyToken(address keyToken) external onlyGovernance validKeyToken(keyToken) {
    uint256 i;
    for ( i=0;i<keyTokens.length;i++) {
      if (keyToken == keyTokens[i]){
        break;
      }
    }
    while (i<keyTokens.length-1) {
      keyTokens[i] = keyTokens[i+1];
      i++;
    }
    keyTokens.pop();
    emit KeyTokenRemoved(keyToken);

    if (checkPricingToken(keyToken)) {
      removePricingToken(keyToken);
    }
  }
  function removePricingToken(address pricingToken) public onlyGovernance validPricingToken(pricingToken) {
    uint256 i;
    for (i=0;i<pricingTokens.length;i++) {
      if (pricingToken == pricingTokens[i]){
        break;
      }
    }
    while (i<pricingTokens.length-1) {
      pricingTokens[i] = pricingTokens[i+1];
      i++;
    }
    pricingTokens.pop();
    emit PricingTokenRemoved(pricingToken);
  }
  function changeDefinedOutput(address newOutputToken) external onlyGovernance validKeyToken(newOutputToken) {
    address oldOutputToken = definedOutputToken;
    definedOutputToken = newOutputToken;
    emit DefinedOutuptChanged(newOutputToken, oldOutputToken);
  }

  function addCurveException(address newException, uint256 exceptionList) external onlyGovernance {
    (bool check0, bool check1) = checkCurveException(newException);
    require(check0==false && check1 == false, "Already an exception");
    require(exceptionList <= 1, 'Only accepts 0 or 1');
    if (exceptionList == 0) {
      curveExceptionList0.push(newException);
    } else {
      curveExceptionList1.push(newException);
    }
    emit CurveExceptionAdded(newException, exceptionList);
  }
  function removeCurveException(address exception) external onlyGovernance validException(exception) {
    (bool check0,) = checkCurveException(exception);
    uint256 i;
    uint256 j;
    uint256 list;
    if (check0) {
      list = 0;
      for (i=0;i<curveExceptionList0.length;i++) {
        if (exception == curveExceptionList0[i]){
          break;
        }
      }
      while (i<curveExceptionList0.length-1) {
        curveExceptionList0[i] = curveExceptionList0[i+1];
        i++;
      }
      curveExceptionList0.pop();
    } else {
      list = 1;
      for (j=0;j<curveExceptionList1.length;j++) {
        if (exception == curveExceptionList1[j]){
          break;
        }
      }
      while (j<curveExceptionList1.length-1) {
        curveExceptionList1[j] = curveExceptionList1[j+1];
        j++;
      }
      curveExceptionList1.pop();
    }
    emit CurveExceptionRemoved(exception, list);
  }

  //Main function of the contract. Gives the price of a given token in the defined output token.
  //The contract allows for input tokens to be LP tokens from Uniswap, Sushiswap, Curve and 1Inch.
  //In case of LP token, the underlying tokens will be found and valued to get the price.
  function getPrice(address token) external view returns (uint256) {
    if (token == definedOutputToken) {
      return (10**precisionDecimals);
    }
    bool uniSushiLP;
    bool curveLP;
    bool oneInchLP;
    (uniSushiLP, curveLP, oneInchLP) = isLPCheck(token);
    uint256 priceToken;
    uint256 tokenValue;
    uint256 price;
    uint256 i;
    if (uniSushiLP || oneInchLP) {
      address[2] memory tokens;
      uint256[2] memory amounts;
      (tokens, amounts) = (uniSushiLP)? getUniUnderlying(token):getOneInchUnderlying(token);
      for (i=0;i<2;i++) {
        priceToken = computePrice(tokens[i]);
        if (priceToken == 0) {
          price = 0;
          return price;
        }
        tokenValue = priceToken*amounts[i]/10**precisionDecimals;
        price = price + tokenValue;
      }
      return price;
    } else if (curveLP) {
      address[8] memory tokens;
      uint256[8] memory amounts;
      (tokens, amounts) = getCurveUnderlying(token);
      for (i=0;i<tokens.length;i++) {
        if (tokens[i] == address(0)) {
          break;
        }
        priceToken = computePrice(tokens[i]);
        if (priceToken == 0) {
          price = 0;
          return price;
        }
        tokenValue = priceToken*amounts[i]/10**precisionDecimals;
        price = price + tokenValue;
      }
      return price;
    } else {
      return computePrice(token);
    }
  }

  function isLPCheck(address token) public view returns(bool, bool, bool) {
    bool isOneInch = isOneInchCheck(token);
    bool isUniSushi = isUniSushiCheck(token);
    bool isCurve = isCurveCheck(token);
    return (isUniSushi, isCurve, isOneInch);
  }

  //Checks if address is 1Inch LP
  function isOneInchCheck(address token) internal view returns (bool) {
    bool oneInchLP = oneInchFactory.isPool(token);
    return oneInchLP;
  }

  //Checks if address is Uni or Sushi LP. This is done in two steps, because the second step seems to cause errors for some tokens.
  //Only the first step is not deemed accurate enough, as any token could be called UNI-V2.
  function isUniSushiCheck(address token) internal view returns (bool) {
    IUniswapV2Pair pair = IUniswapV2Pair(token);
    string memory uniSymbol = "UNI-V2";
    string memory sushiSymbol = "SLP";
    string memory symbol = pair.symbol();
    if (isEqualString(symbol, uniSymbol)) {
      return checkFactory(pair, uniswapFactoryAddress);
    } else if (isEqualString(symbol, sushiSymbol)) {
      return checkFactory(pair, sushiswapFactoryAddress);
    } else {
      return false;
    }
  }

  function isEqualString(string memory arg1, string memory arg2) internal view returns (bool) {
    bool check = (keccak256(abi.encodePacked(arg1)) == keccak256(abi.encodePacked(arg2)))? true:false;
    return check;
  }

  function checkFactory(IUniswapV2Pair pair, address compareFactory) internal view returns (bool) {
    try pair.factory{gas: 3000}() returns (address factory) {
      bool check = (factory == compareFactory)? true:false;
      return check;
    } catch {
      return false;
    }
  }

  //Checks if address is Curve LP
  function isCurveCheck(address token) internal view returns (bool) {
    address pool = curveRegistry.get_pool_from_lp_token(token);
    bool check = (pool != address(0))? true:false;
    return check;
  }

  //Get underlying tokens and amounts for Uni/Sushi LPs
  function getUniUnderlying(address token) public view returns (address[2] memory, uint256[2] memory) {
    IUniswapV2Pair pair = IUniswapV2Pair(token);
    address[2] memory tokens;
    uint256[2] memory amounts;
    tokens[0] = pair.token0();
    tokens[1] = pair.token1();
    uint256 token0Decimals = ERC20(tokens[0]).decimals();
    uint256 token1Decimals = ERC20(tokens[1]).decimals();
    uint256 supplyDecimals = ERC20(token).decimals();
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 totalSupply = pair.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0*10**(supplyDecimals-token0Decimals+precisionDecimals)/totalSupply;
    amounts[1] = reserve1*10**(supplyDecimals-token1Decimals+precisionDecimals)/totalSupply;
    return (tokens, amounts);
  }

  //Get underlying tokens and amounts for 1Inch LPs
  function getOneInchUnderlying(address token) public view returns (address[2] memory, uint256[2] memory) {
    IMooniswap pair = IMooniswap(token);
    address[2] memory tokens;
    uint256[2] memory amounts;
    tokens[0] = pair.token0();
    tokens[1] = pair.token1();
    uint256 token0Decimals = (tokens[0]==address(0))? 18:ERC20(tokens[0]).decimals();
    uint256 token1Decimals = ERC20(tokens[1]).decimals();
    uint256 supplyDecimals = ERC20(token).decimals();
    uint256 reserve0 = pair.getBalanceForRemoval(tokens[0]);
    uint256 reserve1 = pair.getBalanceForRemoval(tokens[1]);
    uint256 totalSupply = pair.totalSupply();
    if (reserve0 == 0 || reserve1 == 0 || totalSupply == 0) {
      amounts[0] = 0;
      amounts[1] = 0;
      return (tokens, amounts);
    }
    amounts[0] = reserve0*10**(supplyDecimals-token0Decimals+precisionDecimals)/totalSupply;
    amounts[1] = reserve1*10**(supplyDecimals-token1Decimals+precisionDecimals)/totalSupply;

    //1INCH uses ETH, instead of WETH in pools. For further calculations we continue with WETH instead.
    //ETH will always be the first in the pair, so no need to check tokens[1]
    if (tokens[0] == address(0)) {
      tokens[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }
    return (tokens, amounts);
  }

  //Get underlying tokens and amounts for Curve LPs. Curve gives responses in arrays with length 8. There is no need to change their size.
  function getCurveUnderlying(address token) public view returns (address[8] memory, uint256[8] memory) {
    address pool = curveRegistry.get_pool_from_lp_token(token);
    (bool exception0, bool exception1) = checkCurveException(token);
    address[8] memory tokens;
    uint256[8] memory reserves;
    if (exception0) {
      tokens = curveRegistry.get_underlying_coins(pool);
      reserves = curveRegistry.get_balances(pool);
    } else if (exception1) {
      tokens = curveRegistry.get_coins(pool);
      reserves = curveRegistry.get_balances(pool);
    } else {
      tokens = curveRegistry.get_underlying_coins(pool);
      reserves = curveRegistry.get_underlying_balances(pool);
    }

    //Some pools work with ETH instead of WETH. For further calculations and functionality this is changed to WETH address.
    uint256[8] memory decimals;
    uint256 i;
    uint256 totalSupply = IERC20(token).totalSupply();
    uint256 supplyDecimals = ERC20(token).decimals();
    uint256[8] memory amounts;
    for (i=0;i<tokens.length;i++) {
      if (tokens[i] == address(0)){
        break;
      } else if (tokens[i]==0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
        decimals[i] = 18;
        tokens[i] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
      } else {
        decimals[i] = ERC20(tokens[i]).decimals();
      }

      amounts[i] = reserves[i]*10**(supplyDecimals-decimals[i]+precisionDecimals)/totalSupply;
      //Curve has errors in their registry, where amounts are stored with the wrong number of decimals
      //This steps accounts for this. In general there will never be more than 1 of any underlying token
      //per curve LP token. If it is more, the decimals are corrected.
      if (amounts[i] > 10**precisionDecimals) {
        amounts[i] = amounts[i]*10**(decimals[i]-18);
      }
    }
    return (tokens, amounts);
  }

  //Check address for the Curve exception lists.
  function checkCurveException(address token) internal view returns (bool, bool) {
    uint256 i;
    for (i=0;i<curveExceptionList0.length;i++) {
      if (token == curveExceptionList0[i]) {
        return (true, false);
      }
    }
    for (i=0;i<curveExceptionList1.length;i++) {
      if (token == curveExceptionList1[i]) {
        return (false, true);
      }
    }
    return (false, false);
  }

  //General function to compute the price of a token vs the defined output token.
  function computePrice(address token) public view returns (uint256) {
    uint256 price;
    if (token == definedOutputToken) {
      price = 10**precisionDecimals;
    } else if (token == address(0)) {
      price = 0;
    } else {
      (address keyToken, address pool, bool uni, bool sushi) = getLargestPool(token,keyTokens);
      uint256 priceVsKeyToken;
      uint256 keyTokenPrice;
      if (keyToken == address(0)) {
        price = 0;
      } else if (uni) {
        priceVsKeyToken = getPriceVsTokenUni(token,keyToken);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/10**precisionDecimals;
      } else if (sushi) {
        priceVsKeyToken = getPriceVsTokenSushi(token,keyToken);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/10**precisionDecimals;
      } else {
        priceVsKeyToken = getPriceVsTokenCurve(token,keyToken,pool);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/10**precisionDecimals;
      }
    }
    return (price);
  }

  //Checks the results of the different largest pool functions and returns the largest.
  function getLargestPool(address token, address[] memory tokenList) public view returns (address, address, bool, bool) {
    (address uniSushiKeyToken, uint256 uniSushiLiquidity, bool isUni) = getUniSushiLargestPool(token, tokenList);
    (address curveKeyToken, address curvePool, uint256 curveLiquidity) = getCurveLargestPool(token, tokenList);
    if (uniSushiLiquidity > curveLiquidity) {
      bool isSushi = (isUni)? false:true;
      return (uniSushiKeyToken, address(0), isUni, isSushi);
    } else {
      return (curveKeyToken, curvePool, false, false);
    }
  }

  //Gives the Uniswap pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  function getUniSushiLargestPool(address token, address[] memory tokenList) internal view returns (address, uint256, bool) {
    uint256 largestPoolSize = 0;
    address largestKeyToken;
    uint256 poolSize;
    uint256 i;
    uint256 poolSizeUni;
    uint256 poolSizeSushi;
    bool largestPoolisUni;
    for (i=0;i<tokenList.length;i++) {
      address pairAddressUni = uniswapFactory.getPair(token,tokenList[i]);
      address pairAddressSushi = sushiswapFactory.getPair(token,tokenList[i]);
      if (pairAddressUni!=address(0)) {
        poolSizeUni = getUniPoolSize(pairAddressUni, token);
      }
      if (pairAddressSushi!=address(0)) {
        poolSizeSushi = getUniPoolSize(pairAddressSushi, token);
      }
      bool uniDex = (poolSizeUni > poolSizeSushi);
      poolSize = (uniDex)? poolSizeUni:poolSizeSushi;
      if (poolSize > largestPoolSize) {
        largestPoolSize = poolSize;
        largestKeyToken = tokenList[i];
        largestPoolisUni = uniDex;
      }
    }
    return (largestKeyToken, largestPoolSize, largestPoolisUni);
  }

  function getUniPoolSize(address pairAddress, address token) internal view returns(uint256) {
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    address token0 = pair.token0();
    (uint112 poolSize0, uint112 poolSize1,) = pair.getReserves();
    uint256 poolSize = (token==token0)? poolSize0:poolSize1;
    return poolSize;
  }

  //Gives the Curve pool with largest liquidity for a given token and a given tokenset (either keyTokens or pricingTokens)
  //Curve can have multiple pools for a given pair. Research showed that the largest pool is always given as first instance, so only the first needs to be called.
  //In Curve USD based tokens are often pooled with 3Pool. In this case liquidity is the same with USDC, DAI and USDT. When liquidity is found with USDC
  //the loop is stopped, as no larger liquidity will be found with any other asset and this reduces calls.
  function getCurveLargestPool(address token, address[] memory tokenList) internal view returns (address, address, uint256) {
    uint256 largestPoolSize = 0;
    address largestPoolAddress;
    address largestKeyToken;
    uint256 poolSize;
    uint256 i;
    for (i=0;i<tokenList.length;i++) {
      address poolAddress = curveRegistry.find_pool_for_coins(token, tokenList[i],0);
      if (poolAddress == address(0)) {
        continue;
      }
      address lpToken = curveRegistry.get_lp_token(poolAddress);
      (bool exception0,) = checkCurveException(lpToken);
      if (exception0) {
        continue;
      }
      poolSize = getCurveBalance(token, tokenList[i], poolAddress);
      if (poolSize > largestPoolSize) {
        largestPoolSize = poolSize;
        largestKeyToken = tokenList[i];
        largestPoolAddress = poolAddress;
        if (largestKeyToken == definedOutputToken) {
          return (largestKeyToken, largestPoolAddress, largestPoolSize);
        }
      }
    }
    return (largestKeyToken, largestPoolAddress, largestPoolSize);
  }

  //Gives the balance of a given token in a given pool.
  function getCurveBalance(address tokenFrom, address tokenTo, address pool) internal view returns (uint256) {
    uint256 balance;
    (int128 indexFrom,,bool underlying) = curveRegistry.get_coin_indices(pool, tokenFrom, tokenTo);
    uint256[8] memory balances;
    if (underlying) {
      balances = curveRegistry.get_underlying_balances(pool);
      uint256 decimals = ERC20(tokenFrom).decimals();
      balance = balances[uint256(indexFrom)];
      if (balance > 10**(decimals+10)) {
        balance = balance*10**(decimals-18);
      }
    } else {
      balances = curveRegistry.get_balances(pool);
      balance = balances[uint256(indexFrom)];
    }
    return balance;
  }

  //Generic function giving the price of a given token vs another given token on Uniswap.
  function getPriceVsTokenUni(address token0, address token1) internal view returns (uint256) {
    address pairAddress = uniswapFactory.getPair(token0,token1);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 token0Decimals = ERC20(token0).decimals();
    uint256 token1Decimals = ERC20(token1).decimals();
    uint256 price;
    if (token0 == pair.token0()) {
      price = (reserve1*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve0;
    } else {
      price = (reserve0*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve1;
    }
    return price;
  }

  //Generic function giving the price of a given token vs another given token on Sushiswap.
  function getPriceVsTokenSushi(address token0, address token1) internal view returns (uint256) {
    address pairAddress = sushiswapFactory.getPair(token0,token1);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 token0Decimals = ERC20(token0).decimals();
    uint256 token1Decimals = ERC20(token1).decimals();
    uint256 price;
    if (token0 == pair.token0()) {
      price = (reserve1*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve0;
    } else {
      price = (reserve0*10**(token0Decimals-token1Decimals+precisionDecimals))/reserve1;
    }
    return price;
  }

  //Generic function giving the price of a given token vs another given token on Curve.
  function getPriceVsTokenCurve(address token0, address token1, address poolAddress) internal view returns (uint256) {
    ICurvePool pool = ICurvePool(poolAddress);
    (int128 indexFrom, int128 indexTo, bool underlying) = curveRegistry.get_coin_indices(poolAddress, token0, token1);
    uint256 decimals0 = ERC20(token0).decimals();
    uint256 decimals1 = ERC20(token1).decimals();
    //Accuracy is impacted when one of the tokens has low decimals.
    //This addition does not impact the outcome of computation, other than increased accuracy.
    if (decimals0 < 4 || decimals1 < 4) {
      decimals0 = decimals0 + 4;
      decimals1 = decimals1 + 4;
    }
    uint256 amount1;
    uint256 price;
    if (underlying) {
      amount1 = pool.get_dy_underlying(indexFrom, indexTo, 10**decimals0);
      price = amount1*10**(precisionDecimals-decimals1);
    } else {
      amount1 = pool.get_dy(indexFrom, indexTo, 10**decimals0);
      price = amount1*10**(precisionDecimals-decimals1);
    }
    return price;
  }

  //Gives the price of a given keyToken.
  function getKeyTokenPrice(address token) internal view returns (uint256) {
    bool isPricingToken = checkPricingToken(token);
    uint256 price;
    uint256 priceVsPricingToken;
    if (token == definedOutputToken) {
      price = 10**precisionDecimals;
    } else if (isPricingToken) {
      price = getPriceVsTokenUni(token,definedOutputToken);
    } else {
      uint256 pricingTokenPrice;
      (address pricingToken, address pricingPool, bool uni, bool sushi) = getLargestPool(token,pricingTokens);
      if (uni) {
        priceVsPricingToken = getPriceVsTokenUni(token,pricingToken);
      } else if (sushi) {
        priceVsPricingToken = getPriceVsTokenSushi(token,pricingToken);
      } else {
        priceVsPricingToken = getPriceVsTokenCurve(token,pricingToken,pricingPool);
      }
      pricingTokenPrice = (pricingToken == definedOutputToken)? 10**precisionDecimals:getPriceVsTokenUni(pricingToken,definedOutputToken);
      price = priceVsPricingToken*pricingTokenPrice/10**precisionDecimals;
    }
    return price;
  }

  //Checks if a given token is in the pricingTokens list.
  function checkPricingToken(address token) public view returns (bool) {
    uint256 i;
    for (i=0;i<pricingTokens.length;i++) {
      if (token == pricingTokens[i]) {
        return true;
      }
    }
    return false;
  }

  //Checks if a given token is in the keyTokens list.
  function checkKeyToken(address token) public view returns (bool) {
    uint256 i;
    for (i=0;i<keyTokens.length;i++) {
      if (token == keyTokens[i]) {
        return true;
      }
    }
    return false;
  }
}
