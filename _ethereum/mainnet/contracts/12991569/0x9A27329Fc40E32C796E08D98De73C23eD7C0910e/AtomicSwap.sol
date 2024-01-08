// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IFinder.sol";
import "./IRegistry.sol";
import "./IPoolOnChainPriceFeed.sol";
import "./Constants.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract AtomicSwap {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Variables
  ISynthereumFinder public synthereumFinder;

  IUniswapV2Router02 public uniswapRouter;

  // Events
  event Swap(
    address indexed inpuToken,
    uint256 inputAmount,
    address indexed outputToken,
    uint256 outputAmount
  );

  constructor(
    ISynthereumFinder _synthereumFinder,
    IUniswapV2Router02 _uniswapRouter
  ) public {
    synthereumFinder = _synthereumFinder;
    uniswapRouter = _uniswapRouter;
  }

  receive() external payable {}

  // Functions

  // Transaction overview:
  // 1. User approves transfer of token to AtomicSwap contract (triggered by the frontend)
  // 2. User calls AtomicSwap.swapExactTokensAndMint() (triggered by the frontend)
  //    2.1 AtomicSwap transfers token from user to itself (internal tx)
  //    2.2 AtomicSwap approves IUniswapV2Router02 (internal tx)
  //    2.3 AtomicSwap calls IUniswapV2Router02.swapExactTokensForTokens() to exchange token for collateral (internal tx)
  //    2.4 AtomicSwap approves SynthereumPool (internal tx)
  //    2.5 AtomicSwap calls SynthereumPool.mint() to mint synth with collateral (internal tx)
  function swapExactTokensAndMint(
    uint256 tokenAmountIn,
    uint256 collateralAmountOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  )
    public
    returns (
      uint256 collateralOut,
      IERC20 synthToken,
      uint256 syntheticTokensMinted
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    uint256 numberOfSwapTokens = tokenSwapPath.length - 1;
    require(
      address(collateralInstance) == tokenSwapPath[numberOfSwapTokens],
      'Wrong collateral instance'
    );

    synthToken = synthereumPool.syntheticToken();
    IERC20 inputTokenInstance = IERC20(tokenSwapPath[0]);

    inputTokenInstance.safeTransferFrom(
      msg.sender,
      address(this),
      tokenAmountIn
    );

    inputTokenInstance.safeApprove(address(uniswapRouter), tokenAmountIn);

    collateralOut = uniswapRouter.swapExactTokensForTokens(
      tokenAmountIn,
      collateralAmountOut,
      tokenSwapPath,
      address(this),
      mintParams.expiration
    )[numberOfSwapTokens];

    collateralInstance.safeApprove(address(synthereumPool), collateralOut);

    mintParams.collateralAmount = collateralOut;
    (syntheticTokensMinted, ) = synthereumPool.mint(mintParams);

    emit Swap(
      address(inputTokenInstance),
      tokenAmountIn,
      address(synthToken),
      syntheticTokensMinted
    );
  }

  // Transaction overview:
  // 1. User approves transfer of token to AtomicSwap contract (triggered by the frontend)
  // 2. User calls AtomicSwap.swapTokensForExactAndMint() (triggered by the frontend)
  //    2.1 AtomicSwap transfers token from user to itself (internal tx)
  //    2.2 AtomicSwap approves IUniswapV2Router02 (internal tx)
  //    2.3 AtomicSwap checks the return amounts of the swapTokensForExactTokens() function and saves the leftover of the inputTokenAmount in a variable
  //    2.4 AtomicSwap calls IUniswapV2Router02.swapTokensForExactTokens() to exchange token for collateral (internal tx)
  //    2.5 AtomicSwap approves SynthereumPool (internal tx)
  //    2.6 AtomicSwap calls SynthereumPool.mint() to mint synth with collateral (internal tx)
  //    2.7 AtomicSwap transfers the remaining input tokens to the user

  function swapTokensForExactAndMint(
    uint256 tokenAmountIn,
    uint256 collateralAmountOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  )
    public
    returns (
      uint256 collateralOut,
      IERC20 synthToken,
      uint256 syntheticTokensMinted
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    uint256 numberOfSwapTokens = tokenSwapPath.length - 1;
    require(
      address(collateralInstance) == tokenSwapPath[numberOfSwapTokens],
      'Wrong collateral instance'
    );

    synthToken = synthereumPool.syntheticToken();
    IERC20 inputTokenInstance = IERC20(tokenSwapPath[0]);

    inputTokenInstance.safeTransferFrom(
      msg.sender,
      address(this),
      tokenAmountIn
    );

    uint256[2] memory amounts =
      _getNeededAmountAndLeftover(
        collateralAmountOut,
        tokenSwapPath,
        tokenAmountIn
      );

    inputTokenInstance.safeApprove(address(uniswapRouter), amounts[0]);

    collateralOut = uniswapRouter.swapTokensForExactTokens(
      collateralAmountOut,
      amounts[0],
      tokenSwapPath,
      address(this),
      mintParams.expiration
    )[numberOfSwapTokens];

    collateralInstance.safeApprove(address(synthereumPool), collateralOut);

    mintParams.collateralAmount = collateralOut;
    (syntheticTokensMinted, ) = synthereumPool.mint(mintParams);

    if (amounts[1] != 0) {
      inputTokenInstance.safeTransfer(mintParams.recipient, amounts[1]);
    }

    emit Swap(
      address(inputTokenInstance),
      tokenAmountIn,
      address(synthToken),
      syntheticTokensMinted
    );
  }

  // Transaction overview:
  // 1. User approves transfer of synth to `AtomicSwap` contract (triggered by the frontend)
  // 2. User calls `AtomicSwap.redeemAndSwapExactTokens()` (triggered by the frontend)
  //   2.1 `AtomicSwaps` transfers synth from user to itself (internal tx)
  //   2.2 `AtomicSwaps` approves transfer of synth from itself to pool (internal tx)
  //   2.3 `AtomicSwap` calls `pool.redeem()` to redeem synth for collateral (internal tx)
  //   2.4 `AtomicSwap` approves transfer of collateral to `IUniswapV2Router02` (internal tx)
  //   2.7 `AtomicSwap` calls `IUniswapV2Router02.swapExactTokensForTokens` to swap collateral for token (internal tx)

  function redeemAndSwapExactTokens(
    uint256 amountTokenOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams,
    address recipient
  )
    public
    returns (
      uint256 collateralRedeemed,
      IERC20 outputToken,
      uint256 outputTokenAmount
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    require(
      address(collateralInstance) == tokenSwapPath[0],
      'Wrong collateral instance'
    );

    IERC20 synthToken = synthereumPool.syntheticToken();
    outputToken = IERC20(tokenSwapPath[tokenSwapPath.length - 1]);

    uint256 numTokens = redeemParams.numTokens;
    synthToken.safeTransferFrom(msg.sender, address(this), numTokens);
    synthToken.safeApprove(address(synthereumPool), numTokens);

    redeemParams.recipient = address(this);
    (collateralRedeemed, ) = synthereumPool.redeem(redeemParams);

    collateralInstance.safeApprove(address(uniswapRouter), collateralRedeemed);

    outputTokenAmount = uniswapRouter.swapExactTokensForTokens(
      collateralRedeemed,
      amountTokenOut,
      tokenSwapPath,
      recipient,
      redeemParams.expiration
    )[tokenSwapPath.length - 1];

    emit Swap(
      address(synthToken),
      numTokens,
      address(outputToken),
      outputTokenAmount
    );
  }

  // Transaction overview:
  // 1. User approves transfer of synth to `AtomicSwap` contract (triggered by the frontend)
  // 2. User calls `AtomicSwap.redeemAndSwapTokensForExact()` (triggered by the frontend)
  //   2.1 `AtomicSwaps` transfers synth from user to itself (internal tx)
  //   2.2 `AtomicSwaps` approves transfer of synth from itself to pool (internal tx)
  //   2.3 `AtomicSwap` calls `pool.redeem()` to redeem synth for collateral (internal tx)
  //   2.4 `AtomicSwap` approves transfer of collateral to `IUniswapV2Router02` (internal tx)
  //   2.5 AtomicSwap checks the return amounts from the swapTokensForExactTokens() function and saves the leftover of inputTokens in a variable
  //   2.6 `AtomicSwap` calls `IUniswapV2Router02.swapTokensForExactTokens` to swap collateral for token (internal tx)
  //   2.7 AtomicSwap transfers the leftover amount to the user if there is any

  function redeemAndSwapTokensForExact(
    uint256 amountTokenOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams,
    address recipient
  )
    public
    returns (
      uint256 collateralRedeemed,
      IERC20 outputToken,
      uint256 outputTokenAmount
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    require(
      address(collateralInstance) == tokenSwapPath[0],
      'Wrong collateral instance'
    );

    IERC20 synthToken = synthereumPool.syntheticToken();
    outputToken = IERC20(tokenSwapPath[tokenSwapPath.length - 1]);

    uint256 numTokens = redeemParams.numTokens;
    synthToken.safeTransferFrom(msg.sender, address(this), numTokens);
    synthToken.safeApprove(address(synthereumPool), numTokens);

    redeemParams.recipient = address(this);
    (collateralRedeemed, ) = synthereumPool.redeem(redeemParams);

    uint256[2] memory amounts =
      _getNeededAmountAndLeftover(
        amountTokenOut,
        tokenSwapPath,
        collateralRedeemed
      );

    collateralInstance.safeApprove(address(uniswapRouter), amounts[0]);

    outputTokenAmount = uniswapRouter.swapTokensForExactTokens(
      amountTokenOut,
      amounts[0],
      tokenSwapPath,
      recipient,
      redeemParams.expiration
    )[tokenSwapPath.length - 1];

    if (amounts[1] != 0) {
      collateralInstance.safeTransfer(recipient, amounts[1]);
    }

    emit Swap(
      address(synthToken),
      numTokens,
      address(outputToken),
      outputTokenAmount
    );
  }

  // Transaction overview:
  // 1. User calls AtomicSwap.swapExactETHAndMint() sending Ether (triggered by the frontend)
  //    1.1 AtomicSwap calls IUniswapV2Router02.swapExactETHForTokens() to exchange ETH for collateral (internal tx)
  //    1.2 AtomicSwap approves SynthereumPool (internal tx)
  //    1.3 AtomicSwap calls SynthereumPool.mint() to mint synth with collateral (internal tx)
  function swapExactETHAndMint(
    uint256 collateralAmountOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  )
    public
    payable
    returns (
      uint256 collateralOut,
      IERC20 synthToken,
      uint256 syntheticTokensMinted
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    uint256 numberOfSwapTokens = tokenSwapPath.length - 1;
    require(
      address(collateralInstance) == tokenSwapPath[numberOfSwapTokens],
      'Wrong collateral instance'
    );
    synthToken = synthereumPool.syntheticToken();

    collateralOut = uniswapRouter.swapExactETHForTokens{value: msg.value}(
      collateralAmountOut,
      tokenSwapPath,
      address(this),
      mintParams.expiration
    )[numberOfSwapTokens];

    collateralInstance.safeApprove(address(synthereumPool), collateralOut);

    mintParams.collateralAmount = collateralOut;
    (syntheticTokensMinted, ) = synthereumPool.mint(mintParams);

    emit Swap(
      address(0),
      msg.value,
      address(synthToken),
      syntheticTokensMinted
    );
  }

  // Transaction overview:
  // 1. User calls AtomicSwap.swapETHForExactAndMint() sending Ether (triggered by the frontend)
  //    1.1 AtomicSwap checks the return amounts from the IUniswapV2Router02.swapETHForExactTokens()
  //    1.2 AtomicSwap saves the leftover ETH that won't be used in a variable
  //    1.3 AtomicSwap calls IUniswapV2Router02.swapETHForExactTokens() to exchange ETH for collateral (internal tx)
  //    1.4 AtomicSwap approves SynthereumPool (internal tx)
  //    1.5 AtomicSwap calls SynthereumPool.mint() to mint synth with collateral (internal tx)
  //    1.6 AtomicSwap transfers the remaining ETH from the transactions to the user

  function swapETHForExactAndMint(
    uint256 collateralAmountOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  )
    public
    payable
    returns (
      uint256 collateralOut,
      IERC20 synthToken,
      uint256 syntheticTokensMinted
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    uint256 numberOfSwapTokens = tokenSwapPath.length - 1;
    require(
      address(collateralInstance) == tokenSwapPath[numberOfSwapTokens],
      'Wrong collateral instance'
    );
    synthToken = synthereumPool.syntheticToken();

    collateralOut = uniswapRouter.swapETHForExactTokens{value: msg.value}(
      collateralAmountOut,
      tokenSwapPath,
      address(this),
      mintParams.expiration
    )[numberOfSwapTokens];

    collateralInstance.safeApprove(address(synthereumPool), collateralOut);

    mintParams.collateralAmount = collateralOut;
    (syntheticTokensMinted, ) = synthereumPool.mint(mintParams);

    if (address(this).balance != 0) {
      msg.sender.transfer(address(this).balance);
    }

    emit Swap(
      address(0),
      msg.value,
      address(synthToken),
      syntheticTokensMinted
    );
  }

  // Transaction overview:
  // 1. User approves transfer of synth to `AtomicSwap` contract (triggered by the frontend)
  // 2. User calls `AtomicSwap.redeemAndSwapExactTokensForETH()` (triggered by the frontend)
  //   2.1 `AtomicSwaps` transfers synth from user to itself (internal tx)
  //   2.2 `AtomicSwaps` approves transfer of synth from itself to pool (internal tx)
  //   2.3 `AtomicSwap` calls `pool.redeem()` to redeem synth for collateral (internal tx)
  //   2.4 `AtomicSwap` approves transfer of collateral to `IUniswapV2Router02` (internal tx)
  //   2.5 `AtomicSwap` calls `IUniswapV2Router02.swapExactTokensForETH` to swap collateral for ETH (internal tx)
  function redeemAndSwapExactTokensForETH(
    uint256 amountTokenOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams,
    address recipient
  )
    public
    returns (
      uint256 collateralRedeemed,
      IERC20 outputToken,
      uint256 outputTokenAmount
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    require(
      address(collateralInstance) == tokenSwapPath[0],
      'Wrong collateral instance'
    );

    IERC20 synthToken = synthereumPool.syntheticToken();

    uint256 numTokens = redeemParams.numTokens;
    synthToken.safeTransferFrom(msg.sender, address(this), numTokens);
    synthToken.safeApprove(address(synthereumPool), numTokens);

    redeemParams.recipient = address(this);
    (collateralRedeemed, ) = synthereumPool.redeem(redeemParams);

    collateralInstance.safeApprove(address(uniswapRouter), collateralRedeemed);

    outputTokenAmount = uniswapRouter.swapExactTokensForETH(
      collateralRedeemed,
      amountTokenOut,
      tokenSwapPath,
      recipient,
      redeemParams.expiration
    )[tokenSwapPath.length - 1];

    emit Swap(
      address(synthToken),
      numTokens,
      address(outputToken),
      outputTokenAmount
    );
  }

  // Transaction overview:
  // 1. User approves transfer of synth to `AtomicSwap` contract (triggered by the frontend)
  // 2. User calls `AtomicSwap.redeemAndSwapTokensForExactETH()` (triggered by the frontend)
  //   2.1 `AtomicSwaps` transfers synth from user to itself (internal tx)
  //   2.2 `AtomicSwaps` approves transfer of synth from itself to pool (internal tx)
  //   2.3 `AtomicSwap` calls `pool.redeem()` to redeem synth for collateral (internal tx)
  //   2.4 `AtomicSwap` approves transfer of collateral to `IUniswapV2Router02` (internal tx)
  //   2.5 AtomicSwap checks what would be the leftover of tokens after the swap and saves it in a variable
  //   2.6 `AtomicSwap` calls `IUniswapV2Router02.swapTokensForExactETH` to swap collateral for ETH (internal tx)
  //   2.7 AtomicSwap transfers the leftover tokens to the user if there are any
  function redeemAndSwapTokensForExactETH(
    uint256 amountTokenOut,
    address[] calldata tokenSwapPath,
    ISynthereumPoolOnChainPriceFeed synthereumPool,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams,
    address recipient
  )
    public
    returns (
      uint256 collateralRedeemed,
      IERC20 outputToken,
      uint256 outputTokenAmount
    )
  {
    IERC20 collateralInstance = checkPoolRegistration(synthereumPool);
    require(
      address(collateralInstance) == tokenSwapPath[0],
      'Wrong collateral instance'
    );

    IERC20 synthToken = synthereumPool.syntheticToken();

    uint256 numTokens = redeemParams.numTokens;
    synthToken.safeTransferFrom(msg.sender, address(this), numTokens);
    synthToken.safeApprove(address(synthereumPool), numTokens);

    redeemParams.recipient = address(this);
    (collateralRedeemed, ) = synthereumPool.redeem(redeemParams);

    uint256[2] memory amounts =
      _getNeededAmountAndLeftover(
        amountTokenOut,
        tokenSwapPath,
        collateralRedeemed
      );

    collateralInstance.safeApprove(address(uniswapRouter), amounts[0]);

    outputTokenAmount = uniswapRouter.swapTokensForExactETH(
      amountTokenOut,
      amounts[0],
      tokenSwapPath,
      recipient,
      redeemParams.expiration
    )[tokenSwapPath.length - 1];

    if (amounts[1] != 0) {
      collateralInstance.safeTransfer(recipient, amounts[1]);
    }

    emit Swap(
      address(synthToken),
      numTokens,
      address(outputToken),
      outputTokenAmount
    );
  }

  // Checks if a pool is registered with the SynthereumRegistry
  function checkPoolRegistration(ISynthereumPoolOnChainPriceFeed synthereumPool)
    internal
    view
    returns (IERC20 collateralInstance)
  {
    ISynthereumRegistry poolRegistry =
      ISynthereumRegistry(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.PoolRegistry
        )
      );
    string memory synthTokenSymbol = synthereumPool.syntheticTokenSymbol();
    collateralInstance = synthereumPool.collateralToken();
    uint8 version = synthereumPool.version();
    require(
      poolRegistry.isDeployed(
        synthTokenSymbol,
        collateralInstance,
        version,
        address(synthereumPool)
      ),
      'Pool not registred'
    );
  }

  function _getNeededAmountAndLeftover(
    uint256 tokenOuput,
    address[] memory path,
    uint256 readyAmount
  ) internal view returns (uint256[2] memory amounts) {
    uint256 neededAmount = uniswapRouter.getAmountsIn(tokenOuput, path)[0];
    uint256 leftover = readyAmount.sub(neededAmount);
    amounts[0] = neededAmount;
    amounts[1] = leftover;
  }
}
