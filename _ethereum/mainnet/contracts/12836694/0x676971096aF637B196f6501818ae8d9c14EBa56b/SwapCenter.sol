// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ISwap.sol";
import "./IVault.sol";
import "./IUniswapV2Router02.sol";
import "./IFarm.sol";
import "./IOneInchAMM.sol";
import "./IOneSplit.sol";
import "./ISushiBar.sol";
import "./IWETH.sol";
import "./ISwapRouter.sol";
import "./ICurve.sol";
import "./ICurveAddressProvider.sol";
import "./ICurveRegistry.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./console.sol";

/// SwapCenter is used for:
/// 
/// 1. Converting the baseAsset to longAsset in the Vault
///
/// 2. Helping users deposit to the Vault with alterative assets.
///
/// The asset swapping is done with pre-defined routes accross multiple external DEXs and contracts.
contract SwapCenter is ISwap, ReentrancyGuard, Ownable {
  // V2 should consume storage then access control, for now we will use onlyOwner
  
  // SUSHI => ETH => WBTC => BADGER => DIGG
  // sushi: SUSHI => ETH
  // uniswap: ETH => WBTC => BADGER => DIGG
  // sushi.swapExactTokensForTokens(x, x, [SUSHI, ETH], x, x)
  // uniswap.swapExactTokensForTokens(x, x, [ETH, WBTC, BADGER, DIGG], x, x)

  using SafeERC20 for IERC20;

  mapping(address => mapping(address => Route)) routes;

  /// The length of exchangeOrder should be exactly the same as intermediateAssetOrder
  /// See setRoute for details.
  struct Route {
    uint256[] exchangeOrder;
    address[][] path;
  }

  // Exchange ID for converting between ETH and WETH
  uint256 constant WETH_ID = type(uint256).max;
  // Exchange ID for depositing into VaultUpgradeable.
  uint256 constant VAULT_DEPOSIT_ID = type(uint256).max -1 ;
  // Exchange ID for swapping with Uniswap v2.
  uint256 constant UNISWAPV2_ID = 0;
  // Exchange ID for swapping with Sushi Swap v2.
  uint256 constant SUSHISWAP_ID = 1;
  // Exchange ID for swapping with 1inch AMM.
  uint256 constant ONEINCHAMM_ID = 2;
  // Exchange ID for swapping with 1inch aggregator.
  uint256 constant ONEINCHAGG_ID = 3;
  // Exchange ID for converting between FARM and iFARM.
  uint256 constant FARMVAULT_ID = 4;
  // Exchange ID for converting between SUSHI and xSUSHI.
  uint256 constant SUSHIBAR_ID = 5;
  // Exchange ID for swapping with Uniswap v3.
  uint256 constant UNISWAPV3_ID = 6;
  // Exchange ID for removing liquidity from Curve.
  uint256 constant CURVE_RM_LIQ_ID = 7;
  // Exchange ID for adding liquidity to Curve.
  uint256 constant CURVE_ADD_LIQ_ID = 8;


  // We use this address for ETH.
  address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  mapping(address => mapping(address => address)) oneInchAMM_pools;
  mapping(address => mapping(address => uint24)) uniV3_fees;
  mapping(address => address) curvePool; // token => pool
  address public referralAddress;

  constructor () {
  }
  
  /// Set the referal addresss.
  /// @param _newReferral The referral address.
  function setReferalAddress(address _newReferral) public onlyOwner {
    referralAddress = _newReferral;
  }

  /// @param token address
  /// @return Return true if the address is ETH_ADDRESS
  function isETH(address token) public pure returns (bool){
    return (token == ETH_ADDRESS);
  }

  /// Get the exchangeOrder for swapping a pair of token.
  /// @return exchangeOrder. See setRoute function for details.
  function getExchangeOrder(address tokenIn, address tokenOut) public view returns (uint256[] memory) {
    Route memory curRoute = routes[tokenIn][tokenOut];
    return curRoute.exchangeOrder;
  }

  /// Get the path for swapping a pair of token.
  /// @return path. See setRoute function for details.
  function getPath(address tokenIn, address tokenOut) public view returns (address[][] memory) {
    Route memory curRoute = routes[tokenIn][tokenOut];
    return curRoute.path;
  }

  /// Set the pre-defined route for swapping a pair of token.
  /// To create a reversed swapping route, a separate route has to be created.
  /// @param input Address of the input token.
  /// @param output Address of the output token.
  /// @param exchangeOrder A list of DEXs or contracts used for swapping.
  /// @param path A list of paths used in each DEXs or contracts for swapping. The length of path should be the same as the length of exchangeOrder.
  function setRoute(address input, address output, uint256[] memory exchangeOrder, address[][] memory path) public onlyOwner {
    routes[input][output] = Route({
      exchangeOrder: exchangeOrder,
      path: path
    });
  }

  /// Create pre-defined routes in batch. See setRoute function for details.
  function setRouteBatch(address[] memory input, address[] memory output, uint256[][] memory exchangeOrder, address[][][] memory path) public onlyOwner {
    for(uint256 i = 0 ; i < input.length; i++){
      setRoute(input[i], output[i], exchangeOrder[i], path[i]);
    }
  }
  /// Swap the tokens with pre-defined routes.
  /// @param tokenIn Address of the input token.
  /// @param tokenOut Address of the output token.
  /// @param amountIn Amount of the input token.
  /// @param minAmountOut The minimum amount of the output token expected to receive. If the output amount is smaller than this value, the transaction will be reverted.
  function swapExactTokenIn(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut) external override payable nonReentrant returns (uint256) {

    if(isETH(tokenIn)){
      require(msg.value == amountIn, "Amount of Ether sent doesn't match amountIn argument");
    } else {
      require(msg.value == 0, "Shouldn't receive Ether when the tokenIn is not Ether");
      IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
    }

    Route memory curRoute = routes[tokenIn][tokenOut];

    uint256 exchangeLen = curRoute.exchangeOrder.length;
    require(exchangeLen > 0, "Undefined pair");

    for(uint256 i = 0; i < exchangeLen; i++) {
      address[] memory curSellPath = curRoute.path[i];
      uint256 exchangeId = curRoute.exchangeOrder[i];

      // address swapContract = swapImplementation[exchangeId]
      // ISwapImplementation(swapContract).swap(curSellPath);
      if(exchangeId == UNISWAPV2_ID) {
        _swapExactTokenIn_uniswapType(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, curSellPath);
      } else if (exchangeId == SUSHISWAP_ID) {
        _swapExactTokenIn_uniswapType(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F, curSellPath);
      } else if (exchangeId == ONEINCHAMM_ID) {
         _swapOneInchAMM(curSellPath);
      } else if (exchangeId == ONEINCHAGG_ID) {
        _swapOneInchAgg(curSellPath);
      } else if (exchangeId == FARMVAULT_ID) {
        _swapIFARM(curSellPath);
      } else if (exchangeId == SUSHIBAR_ID) {
        _swapXSUSHI(curSellPath);
      } else if (exchangeId == UNISWAPV3_ID) {
        _swapUniSwapV3(curSellPath);
      } else if (exchangeId == CURVE_RM_LIQ_ID) {
        _swapRemoveCurveLiquidity(curSellPath);
      } else if (exchangeId == CURVE_ADD_LIQ_ID) {
        _swapAddCurveLiquidity(curSellPath);
      } else if (exchangeId == VAULT_DEPOSIT_ID) {
        _swapDepositVault(curSellPath);
      } else if (exchangeId == WETH_ID) {
        _swapWETH(curSellPath);
      } else {
        revert("exchange id not supported");
      }
    }

    uint256 lastAmountOut;
    if(tokenOut == ETH_ADDRESS) {
      lastAmountOut = address(this).balance;
      require(lastAmountOut >= minAmountOut, "acquired too few Ether");

      (bool success, ) = (msg.sender).call{value: lastAmountOut}("");
      require(success, "failed to send ETH to msg.sender");
    } else {
      lastAmountOut = IERC20(tokenOut).balanceOf(address(this));
      require(lastAmountOut >= minAmountOut, "acquired too few output tokens");

      IERC20(tokenOut).safeTransfer(msg.sender, lastAmountOut);
    }
    return lastAmountOut;
  }

  function _swapExactTokenIn_uniswapType(address router, address[] memory path) internal {
    address curInputToken = path[0];
    uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
    IERC20(curInputToken).safeApprove(router, 0);
    IERC20(curInputToken).safeApprove(router, amountIn);
    IUniswapV2Router02(router).swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
  }

  /// Set the 1inch AMM pool to use. The order of token1 and token2 doesn't matter.
  /// @param token1 One of the token in the AMM pool.
  /// @param token2 One of the token in the AMM pool.
  /// @param pool The address of the 1inch AMM pool.
  function setOneInchPool(address token1, address token2, address pool) external onlyOwner {
    if(token1 > token2){
      (token1, token2) = (token2, token1);
    }
    oneInchAMM_pools[token1][token2] = pool;
  }


  function _swapOneInchAMM(address[] memory path) internal {

    require(path.length == 2, "Unsupported path");
    address curInputToken = path[0];
    address curOutputToken = path[1];

    address token1 = curInputToken;
    address token2 = curOutputToken;

    if(token1 > token2){
      (token1, token2) = (token2, token1);
    }
    address pool = oneInchAMM_pools[token1][token2];

    // 1inch use address(0) to represent eth
    if(isETH(curOutputToken))
    {
      curOutputToken = address(0);
    }

    if(isETH(curInputToken))
    {
      uint256 amountIn = address(this).balance;
      uint256 result = IOneInchAMM(pool).swap{value:amountIn}(address(0), curOutputToken, amountIn, 0, referralAddress);
    }else{
      uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
      IERC20(curInputToken).safeApprove(pool, 0);
      IERC20(curInputToken).safeApprove(pool, amountIn);
      uint256 result = IOneInchAMM(pool).swap(curInputToken, curOutputToken, amountIn, 0, referralAddress);
    }

  }

  function _swapOneInchAgg(address[] memory path) internal {
    require(path.length == 2, "Unsupported path");

    address oneInch_address = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    address curInputToken = path[0];
    address curOutputToken = path[1];
    uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
    IERC20(curInputToken).safeApprove(oneInch_address, 0);
    IERC20(curInputToken).safeApprove(oneInch_address, amountIn);

    uint256 returnAmount;
    uint256[] memory distribution;
    (returnAmount, distribution) = IOneSplit(oneInch_address).getExpectedReturn(
      curInputToken,
      curOutputToken,
      amountIn,
      1,  // Use only one exchange
      0 // default flag. Use all the exchanges
    );

    IOneSplit(oneInch_address).swap(
      curInputToken,
      curOutputToken,
      amountIn,
      0,
      distribution,
      0 // default flag. Use all the exchanges
    );

  }

  function _swapIFARM(address[] memory path) internal{
    require(path.length == 2, "Unsupported path");
    // ifarm address is also the address of farm vault.
    address ifarm_address = 0x1571eD0bed4D987fe2b498DdBaE7DFA19519F651;
    address farm_address = 0xa0246c9032bC3A600820415aE600c6388619A14D;

    address curInputToken = path[0];
    address curOutputToken = path[1];
    uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
    IERC20(curInputToken).safeApprove(ifarm_address, 0);
    IERC20(curInputToken).safeApprove(ifarm_address, amountIn);

    if (curInputToken == farm_address && curOutputToken == ifarm_address) {
      IVaultFarm(ifarm_address).deposit(amountIn);
    } else if (curInputToken == ifarm_address && curOutputToken == farm_address) {
      IVaultFarm(ifarm_address).withdraw(amountIn);
    } else {
      revert("Unsupported pair.");
    }
  }
  function _swapXSUSHI(address[] memory path) internal{
    require(path.length == 2, "Unsupported path");
    address sushi_address = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    // xsushi address is also the address of sushi bar.
    address xsushi_address = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    address curInputToken = path[0];
    address curOutputToken = path[1];
    uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
    IERC20(curInputToken).safeApprove(xsushi_address, 0);
    IERC20(curInputToken).safeApprove(xsushi_address, amountIn);

    if (curInputToken == sushi_address && curOutputToken == xsushi_address) {
      SushiBar(xsushi_address).enter(amountIn);
    } else if (curInputToken == xsushi_address && curOutputToken == sushi_address) {
      SushiBar(xsushi_address).leave(amountIn);
    } else {
      revert("Unsupported pair.");
    }

  }

  /// Set the Uniswap V3 fee for swapping token1 and token2. The order of token1 and token2 doesn't matter.
  /// @param token1 One of the token in the AMM pool.
  /// @param token2 One of the token in the AMM pool.
  /// @param fee The Uniswap V3 fee.(LOW = 500, MEDIUM = 3000, HIGH = 10000)
  function setUniV3Fee(address token1, address token2, uint24 fee) external onlyOwner {
    if(token1 > token2){
      (token1, token2) = (token2, token1);
    }
    uniV3_fees[token1][token2] = fee;
  }

  /// Get the Uniswap V3 fee for swapping token1 and token2. The order of token1 and token2 doesn't matter.
  /// @param token1 One of the token in the AMM pool.
  /// @param token2 One of the token in the AMM pool.
  /// @return fee The Uniswap V3 fee.(LOW = 500, MEDIUM = 3000, HIGH = 10000)
  function getUniV3Fee(address token1, address token2) public view returns (uint24 fee){
    if(token1 > token2){
      (token1, token2) = (token2, token1);
    }

    // https://github.com/Uniswap/uniswap-v3-sdk/blob/2b7997ae08a9eda84698a593786762c066a02046/src/constants.ts
    // LOW = 500
    // MEDIUM = 3000
    // HIGH = 10000
    uint24 fee = uniV3_fees[token1][token2];
    if (fee == 0) {
      fee = 3000; // default fee
    }
    return fee;
  }

  function _swapUniSwapV3(address[] memory path) internal {
    address router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address curInputToken = path[0];
    address curOutputToken;

    uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
    IERC20(curInputToken).safeApprove(router, 0);
    IERC20(curInputToken).safeApprove(router, amountIn);

    bytes memory encodedPath = abi.encodePacked(curInputToken);

    ISwapRouter.ExactInputParams memory param;
    param.recipient = address(this);
    param.amountIn = amountIn;
    param.deadline = uint256(-1); // never expired

    for(uint256 i=1; i< path.length; i++){
      curOutputToken = path[i];
      uint24 fee = getUniV3Fee(curInputToken, curOutputToken);
      encodedPath = abi.encodePacked(encodedPath, fee, curOutputToken);
      curInputToken = curOutputToken;
    }
    param.path = encodedPath;

    ISwapRouter(router).exactInput(param);
  }

  function _swapAddCurveLiquidity(address [] memory path) internal {
    // Limitation: Adding ETH is not supported.
    require(path.length == 2, "Unsupported path");
    address curInputToken = path[0];
    address curLPToken = path[1];
    

    address curveRegistry = ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383).get_registry();

    // fetch pool from registry
    address currentCurvePool = ICurveRegistry(curveRegistry).get_pool_from_lp_token(curLPToken);
    uint256 n_coins = ICurveRegistry(curveRegistry).get_n_coins(currentCurvePool)[0];

    for(uint256 i=0; i < n_coins; i++){
      address coin = ICurve(currentCurvePool).coins(i);
      if(curInputToken == coin){
        uint256 amount = IERC20(curInputToken).balanceOf(address(this));

        IERC20(curInputToken).safeApprove(currentCurvePool, 0);
        IERC20(curInputToken).safeApprove(currentCurvePool, amount);

        if(n_coins==2) {
          uint256[2] memory amounts;
          amounts[i] = amount;
          ICurve(currentCurvePool).add_liquidity(amounts, 0);
        } else if (n_coins==3) {
          uint256[3] memory amounts;
          amounts[i] = amount;
          ICurve(currentCurvePool).add_liquidity(amounts, 0);
        } else if (n_coins==4) {
          uint256[4] memory amounts;
          amounts[i] = amount;
          ICurve(currentCurvePool).add_liquidity(amounts, 0);
        } else if (n_coins==5) {
          uint256[5] memory amounts;
          amounts[i] = amount;
          ICurve(currentCurvePool).add_liquidity(amounts, 0);
        } else {
          revert();
        }

        return;
      }
    }
    revert();
  }

  function _swapRemoveCurveLiquidity(address [] memory path) internal {
    require(path.length == 2, "Unsupported path");
    address curLPToken = path[0];
    address curOutputToken = path[1];
    // fetch registry from address provider
    address curveRegistry = ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383).get_registry();

    // fetch pool from registry
    address  currentCurvePool = ICurveRegistry(curveRegistry).get_pool_from_lp_token(curLPToken);

    for(uint256 i=0; true; i++){
      address coin = ICurve(currentCurvePool).coins(i);
      if(curOutputToken == coin){
        uint256 amount = IERC20(curLPToken).balanceOf(address(this));
        IERC20(curLPToken).safeApprove(currentCurvePool, 0);
        IERC20(curLPToken).safeApprove(currentCurvePool, amount);
        ICurve(currentCurvePool).remove_liquidity_one_coin(
          amount,
          int128(i), 0
        );
        return;
      }
    }
    revert();
  }

  function _swapDepositVault(address[] memory path) internal {
    require(path.length == 2, "Unsupported path");
    address curInputToken = path[0];
    address curVaultToken = path[1];
    uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
    IERC20(curInputToken).safeApprove(curVaultToken, 0);
    IERC20(curInputToken).safeApprove(curVaultToken, amountIn);
    IVault(curVaultToken).deposit(amountIn);
  }

  function _swapWETH(address[] memory path) internal{
    require(path.length == 2, "Unsupported path");

    address curInputToken = path[0];
    address curOutputToken = path[1];

    address weth_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    if (curInputToken == ETH_ADDRESS && curOutputToken == weth_address) {
      uint256 amountIn = address(this).balance;
      IWETH(weth_address).deposit{value:amountIn}();
    } else if (curInputToken == weth_address && curOutputToken == ETH_ADDRESS) {
      uint256 amountIn = IERC20(curInputToken).balanceOf(address(this));
      IERC20(curInputToken).safeApprove(weth_address, 0);
      IERC20(curInputToken).safeApprove(weth_address, amountIn);
      IWETH(weth_address).withdraw(amountIn);
    } else {
      revert("Unsupported pair.");
    }

  }

  /// Rescue ETH from the SwapCenter.
  /// @param to The address that eth will be sent to.
  function rescueETH(address payable to) external onlyOwner {
    (bool sent, bytes memory data) = to.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }
  
  /// Rescue ERC20 token from the SwapCenter.
  /// @param token The address of the ERC20 token.
  /// @param to The address that the token will be sent to.
  /// @param amount The amount of the ERC20 token will be transfered.
  function rescueERC20(address token, address to, uint256 amount) external onlyOwner {
    IERC20(token).safeTransfer(to, amount);
  }

  receive() external payable {

  }
}
