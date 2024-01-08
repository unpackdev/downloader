// SPDX-License-Identifier: MIT
import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";

import "./Governable.sol";
import "./SwapBase.sol";

import "./UniSwap.sol";

pragma solidity 0.6.12;

contract OracleBase is Governable, Initializable  {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  uint256 public constant PRECISION_DECIMALS = 18;
  uint256 public constant ONE = 10**PRECISION_DECIMALS;

  //The defined output token is the unit in which prices of input tokens are given.
  bytes32 internal constant _DEFINED_OUTPUT_TOKEN_SLOT = bytes32(uint256(keccak256("eip1967.OracleBase.definedOutputToken")) - 1);

  //Key tokens are used to find liquidity for any given token on Uni, Sushi and Curve.
  address[] public keyTokens;

  //Pricing tokens are Key tokens with good liquidity with the defined output token on Uniswap.
  address[] public pricingTokens;

  mapping(address => address) replacementTokens;

  //Swap platforms addresses
  address[] public swaps;

  modifier validKeyToken(address keyToken){
      require(checkKeyToken(keyToken), "Not a Key Token");
      _;
  }
  modifier validPricingToken(address pricingToken){
      require(checkPricingToken(pricingToken), "Not a Pricing Token");
      _;
  }
  modifier validSwap(address swap){
      require(checkSwap(swap), "Not a Swap");
      _;
  }

  event RegistryChanged(address newRegistry, address oldRegistry);
  event KeyTokenAdded(address newKeyToken);
  event PricingTokenAdded(address newPricingToken);
  event SwapAdded(address newSwap);
  event KeyTokenRemoved(address keyToken);
  event PricingTokenRemoved(address pricingToken);
  event SwapRemoved(address newSwap);
  event DefinedOutputChanged(address newOutputToken, address oldOutputToken);

  constructor(address[] memory _keyTokens, address[] memory _pricingTokens, address _outputToken)
  public Governable(msg.sender) {
    initialize( _keyTokens, _pricingTokens, _outputToken);
  }

  function initialize(address[] memory _keyTokens, address[] memory _pricingTokens, address _outputToken)
  public initializer {
    Governable.setGovernance(msg.sender);

    addKeyTokens(_keyTokens);
    addPricingTokens(_pricingTokens);
    changeDefinedOutput(_outputToken);
    // after contract deploy you have to set swaps
  }

  function addSwap(address newSwap) public onlyGovernance {
    require(!checkSwap(newSwap), "Already a swap");
    swaps.push(newSwap);
    emit SwapAdded(newSwap);
  }

  function addSwaps(address[] memory newSwaps) public onlyGovernance {
    for(uint i=0; i<newSwaps.length; i++) {
      if (!checkSwap(newSwaps[i])) addSwap(newSwaps[i]);
    }
  }
  function setSwaps(address[] memory newSwaps) external onlyGovernance {
    delete swaps;
    addSwaps(newSwaps);
  }

  function addKeyToken(address newToken) public onlyGovernance {
    require(!checkKeyToken(newToken), "Already a key token");
    keyTokens.push(newToken);
    emit KeyTokenAdded(newToken);
  }

  function addKeyTokens(address[] memory newTokens) public onlyGovernance {
    for(uint i=0; i<newTokens.length; i++) {
      if (!checkKeyToken(newTokens[i])) addKeyToken(newTokens[i]);
    }
  }

  function addPricingToken(address newToken) public onlyGovernance validKeyToken(newToken) {
    require(!checkPricingToken(newToken), "Already a pricing token");
    pricingTokens.push(newToken);
    emit PricingTokenAdded(newToken);
  }

  function addPricingTokens(address[] memory newTokens) public onlyGovernance {
    for(uint i=0; i<newTokens.length; i++) {
      if (!checkPricingToken(newTokens[i])) addPricingToken(newTokens[i]);
    }
  }

  function removeAddressFromArray(address adr, address[] storage array) internal {
    uint i;
    for (i=0; i<array.length; i++) {
      if (adr == array[i]) break;
    }

    while (i<array.length-1) {
      array[i] = array[i+1];
      i++;
    }
    array.pop();
  }

  function removeKeyToken(address keyToken) external onlyGovernance validKeyToken(keyToken) {
    removeAddressFromArray(keyToken, keyTokens);
    emit KeyTokenRemoved(keyToken);

    if (checkPricingToken(keyToken)) {
      removePricingToken(keyToken);
    }
  }

  function removePricingToken(address pricingToken) public onlyGovernance validPricingToken(pricingToken) {
    removeAddressFromArray(pricingToken, pricingTokens );
    emit PricingTokenRemoved(pricingToken);
  }

  function removeSwap(address swap) public onlyGovernance validSwap(swap) {
    removeAddressFromArray(swap, swaps);
    emit SwapRemoved(swap);
  }

  function definedOutputToken() public view returns (address value) {
    bytes32 slot = _DEFINED_OUTPUT_TOKEN_SLOT;
    assembly {
      value := sload(slot)
    }
  }

  function changeDefinedOutput(address newOutputToken) public onlyGovernance validKeyToken(newOutputToken) {
    require(newOutputToken != address(0), "zero address");
    address oldOutputToken = definedOutputToken();
    bytes32 slot = _DEFINED_OUTPUT_TOKEN_SLOT;
    assembly {
      sstore(slot, newOutputToken)
    }
    emit DefinedOutputChanged(newOutputToken, oldOutputToken);
  }

  function modifyReplacementTokens(address _inputToken, address _replacementToken) external onlyGovernance {
    replacementTokens[_inputToken] = _replacementToken;
  }

  //Main function of the contract. Gives the price of a given token in the defined output token.
  //The contract allows for input tokens to be LP tokens from Uniswap, Sushiswap, Curve and 1Inch.
  //In case of LP token, the underlying tokens will be found and valued to get the price.
  function getPrice(address token) external view returns (uint256) {
    if (token == definedOutputToken())
      return (ONE);

    // if the token exists in the mapping, we'll swap it for the replacement
    // example btcb/renbtc pool -> btcb
    if (replacementTokens[token] != address(0)) {
      token = replacementTokens[token];
    }

    uint256 tokenPrice;
    uint256 tokenValue;
    uint256 price = 0;
    uint256 i;
    address swap = getSwapForPool(token);
    if (swap!=address(0)) {
      (address[] memory tokens, uint256[] memory amounts) = SwapBase(swap).getUnderlying(token);
      for (i=0;i<tokens.length;i++) {
        if (tokens[i] == address(0)) break;
        tokenPrice = computePrice(tokens[i]);
        if (tokenPrice == 0) return 0;
        tokenValue = tokenPrice *amounts[i]/ONE;
        price += tokenValue;
      }
      return price;
    } else {
      return computePrice(token);
    }
  }

  function getSwapForPool(address token) public view returns(address) {
    for (uint i=0; i<swaps.length; i++ ) {
      if (SwapBase(swaps[i]).isPool(token)) {
        return swaps[i];
      }
    }
    return address(0);
  }

  //General function to compute the price of a token vs the defined output token.
  function computePrice(address token) public view returns (uint256) {
    uint256 price;
    if (token == definedOutputToken()) {
      price = ONE;
    } else if (token == address(0)) {
      price = 0;
    } else {
      (address swap, address keyToken, address pool) = getLargestPool(token,keyTokens);
      uint256 priceVsKeyToken;
      uint256 keyTokenPrice;
      if (keyToken == address(0)) {
        price = 0;
      } else {
        priceVsKeyToken = SwapBase(swap).getPriceVsToken(token,keyToken,pool);
        keyTokenPrice = getKeyTokenPrice(keyToken);
        price = priceVsKeyToken*keyTokenPrice/ONE;
      }
    }
    return (price);
  }

  //Checks the results of the different largest pool functions and returns the largest.
  function getLargestPool(address token) public view returns (address, address, address) {
    return getLargestPool(token, keyTokens);
  }

  function getLargestPool(address token, address[] memory keyTokenList) public view returns (address, address, address) {
    address largestKeyToken = address(0);
    address largestPool = address(0);
    uint largestPoolSize = 0;
    SwapBase largestSwap;
    for (uint i=0;i<swaps.length;i++) {
      SwapBase swap = SwapBase(swaps[i]);
      (address swapLargestKeyToken, address swapLargestPool, uint swapLargestPoolSize) = swap.getLargestPool(token, keyTokenList);
      if (swapLargestPoolSize>largestPoolSize) {
        largestSwap = swap;
        largestKeyToken = swapLargestKeyToken;
        largestPool = swapLargestPool;
        largestPoolSize = swapLargestPoolSize;
      }
    }
    return (address(largestSwap), largestKeyToken, largestPool);
  }

  //Gives the price of a given keyToken.
  function getKeyTokenPrice(address token) internal view returns (uint256) {
    bool isPricingToken = checkPricingToken(token);
    uint256 price;
    uint256 priceVsPricingToken;
    if (token == definedOutputToken()) {
      price = ONE;
    } else if (isPricingToken) {
      price = SwapBase(swaps[0]).getPriceVsToken(token, definedOutputToken(), address(0)); // first swap is used
      // as at original contract was used
      // mainnet: UniSwap OracleMainnet_old.sol:641
      // bsc: Pancake OracleBSC_old.sol:449
    } else {
      uint256 pricingTokenPrice;
      (address swap, address pricingToken, address pricingPool) = getLargestPool(token,pricingTokens);
      priceVsPricingToken = SwapBase(swap).getPriceVsToken(token, pricingToken, pricingPool);
//      pricingTokenPrice = (pricingToken == definedOutputToken())? ONE : SwapBase(swap).getPriceVsToken(pricingToken,definedOutputToken(),pricingPool);
      // Like in original contract we use UniSwap - it must be first swap at the list (swaps[0])
      // See OracleMainnet_old.js:634, OracleBSC_old.sol:458
      //TODO improve this part?
      pricingTokenPrice = (pricingToken == definedOutputToken())? ONE : SwapBase(swaps[0]).getPriceVsToken(pricingToken,definedOutputToken(),pricingPool);
      price = priceVsPricingToken*pricingTokenPrice/ONE;
    }
    return price;
  }

  //Checks if a given token is in the keyTokens list.
  function addressInArray(address adr, address[] storage array) internal view returns (bool) {
    for (uint i=0; i<array.length; i++)
      if (adr == array[i]) return true;

    return false;
  }

  //Checks if a given token is in the pricingTokens list.
  function checkPricingToken(address token) public view returns (bool) {
    return addressInArray(token, pricingTokens);
  }

  //Checks if a given token is in the keyTokens list.
  function checkKeyToken(address token) public view returns (bool) {
    return addressInArray(token, keyTokens);
  }

  //Checks if a given token is in the swaps list.
  function checkSwap(address swap) public view returns (bool) {
    return addressInArray(swap, swaps);
  }
}
