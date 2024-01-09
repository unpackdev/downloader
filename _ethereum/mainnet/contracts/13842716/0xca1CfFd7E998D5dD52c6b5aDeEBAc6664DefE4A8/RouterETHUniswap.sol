// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IRouter.sol";
import "./SafeERC20.sol";
import "./MyPausableUpgradeable.sol";
import "./console.sol";

interface IUniswapRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function WETH() external returns (address);
}

/**
 * @title RouterETHUniswap
 * This contract implements the router interface for the Ethereum (ETH) network using Uniswap for token swaps
 */
contract RouterETHUniswap is IRouter, MyPausableUpgradeable {
  using SafeERC20 for IERC20;

  struct SwapPath {
    bool exists;
    address[] path;
  }

  // Roles
  bytes32 public constant MANAGE_CONTRACTS_ROLE = keccak256('MANAGE_CONTRACTS_ROLE');
  bytes32 public constant MANAGE_ROUTER_PATHS_ROLE = keccak256('MANAGE_ROUTER_PATHS_ROLE');

  // contains the address of the UniswapRouterV2 in ETH mainnet
  address constant UNISWAP_ROUTER_V2 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  // interface for the UniSwapRouterV2 that enables token swaps
  IUniswapRouter public uniswapRouter;

  // swapPath mappings
  // inputToken => outputToken => swapPath to use
  mapping(address => mapping(address => SwapPath)) public swapPaths;

  /**
   * @notice Initializer instead of constructor to have the contract upgradeable
   *
   * @dev can only be called once after deployment of the contract
   */
  function initialize() public initializer {
    // call parent initializers
    MyPausableUpgradeable.__MyPausableUpgradeable_init();

    // set up admin roles
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // initialize required state variables
    uniswapRouter = IUniswapRouter(UNISWAP_ROUTER_V2);
  }

  /**
   * @notice Returns the address of the wrapped native token that is used by the dex router
   */
  function wrappedNative() external override returns (address) {
    return uniswapRouter.WETH();
  }

  /**
   * @notice Swaps from one ERC20 token to another using an external DEX
   *
   * @param input token contract address of the token that should be swapped (must be an IERC20 contract)
   * @param output token contract address of the token that should be received (must be an IERC20 contract)
   * @param inputAmount amount of input tokens that should be swapped
   * @return returns the amount of (output) tokens that were received in the swap
   */
  function tradeERC20(
    IERC20 input,
    IERC20 output,
    uint256 inputAmount
  ) external override whenNotPaused returns (uint256) {
    // check input parameters
    require(inputAmount > 0, 'RouterETHUniswapV1: inputAmount for token swap cannot be 0');

    // set deadline for token swap
    uint256 deadline = block.timestamp + 60;

    // transfer tokens from the caller (usually BuyBackAndBurn) to this contract
    input.safeTransferFrom(_msgSender(), address(this), inputAmount);

    // register approval for dex to spend input token, if not already done
    if (input.allowance(address(this), UNISWAP_ROUTER_V2) < inputAmount) {
      input.approve(UNISWAP_ROUTER_V2, type(uint256).max);
    }

    // call external DEX and swap tokens
    uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
      inputAmount,
      0,
      _getPathForSwap(address(input), address(output)),
      _msgSender(),
      deadline
    );

    // return swap output amount
    return amounts[1];
  }

  /**
   * @notice Swaps native tokens to ERC20 tokens using an external DEX
   *
   * @param output token contract address of the token that should be received (must be an IERC20 contract)
   * @param inputAmount amount of native tokens that should be swapped
   * @return returns the amount of (output) tokens that were received in the swap
   */
  function tradeNativeTokenForERC20(IERC20 output, uint256 inputAmount)
    external
    payable
    override
    whenNotPaused
    returns (uint256)
  {
    // check input parameters
    require(inputAmount > 0, 'RouterETHUniswapV1: inputAmount for token swap cannot be 0');

    // set deadline for token swap
    uint256 deadline = block.timestamp + 60;

    // call external DEX and swap tokens
    uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: inputAmount}(
      0,
      _getPathForSwap(uniswapRouter.WETH(), address(output)),
      _msgSender(),
      deadline
    );

    // return swap output amount
    return amounts[1];
  }

  /**
   * @notice Sets the contract address of the dex router to be used for token swaps
   *
   * @dev can only be called by MANAGE_CONTRACTS_ROLE
   * @param dexAddress token contract address of the dex router (contract must implement UniswapRouter interface)
   */
  function setDexRouterAddress(address dexAddress) external {
    require(
      hasRole(MANAGE_CONTRACTS_ROLE, _msgSender()),
      'RouterETHUniswapV1: must have MANAGE_CONTRACTS_ROLE role to execute this function'
    );
    require(dexAddress != address(0), 'RouterETHUniswapV1: invalid dex router address provided');
    uniswapRouter = IUniswapRouter(dexAddress);
  }

  /**
   * @notice Adds a swap path for a specific ERC20-to-ERC20 token swap
   *
   * @param input token contract address of the token that should be swapped (must be an IERC20 contract)
   * @param output token contract address of the token that should be received (must be an IERC20 contract)
   * @param path the path that should be used to swap the input token for the output token
   */
  function addSwapPath(
    address input,
    address output,
    address[] memory path
  ) external override {
    require(
      hasRole(MANAGE_ROUTER_PATHS_ROLE, _msgSender()),
      'RouterETHUniswapV1: must have MANAGE_ROUTER_PATHS_ROLE role to execute this function'
    );
    require(
      input != address(0) && output != address(0) && path[0] != address(0),
      'RouterETHUniswapV1: invalid data provided'
    );
    swapPaths[input][output] = SwapPath({exists: true, path: path});
  }

  /**
   * @notice Creates a path which can be used as input parameter for a swap on an external DEX
   *
   * @param input token contract address of the input token
   * @param output token contract address of the output token
   * @return returns an address array with both input addresses (i.e. the path)
   */
  function _getPathForSwap(address input, address output) private returns (address[] memory) {
    if (swapPaths[input][output].exists) {
      return swapPaths[input][output].path;
    } else {
      address[] memory path = new address[](3);
      path[0] = input;
      path[1] = uniswapRouter.WETH();
      path[2] = output;
      return path;
    }
  }
}
