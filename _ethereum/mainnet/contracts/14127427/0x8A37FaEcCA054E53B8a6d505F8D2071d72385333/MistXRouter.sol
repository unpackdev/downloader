// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IUniswap.sol";
import "./IWETH.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./Managable.sol";

/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Router with generic Uniswap-style support
/// @notice If you came here just to copy my stuff, you NGMI - learn to code!
contract MistXRouter is Managable {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  // Managers are permissioned for critical functionality
  mapping (address => bool) public managers;
  address public tipjar;

  address public immutable WETH;
  address public immutable factory;
  bytes32 public immutable initHash;

  receive() external payable {}
  fallback() external payable {}

  constructor(
    address _WETH,
    address _factory,
    bytes32 _initHash,
    address _owner,
    address _tipjar
  ) Managable(_owner) {
    WETH = _WETH;
    factory = _factory;
    initHash = _initHash;
    managers[_owner] = true;
    tipjar = _tipjar;
  }

  /***********************
  + Structures           +
  ***********************/

  struct Swap {
    uint256 amount0;
    uint256 amount1;
    address[] path;
    address to;
    uint256 deadline;
  }

  /***********************
  + Swap wrappers        +
  ***********************/

  function swapExactETHForTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    require(_swap.path[0] == WETH, 'MistXRouter: INVALID_PATH');
    uint amountIn = msg.value - _bribe;
    IWETH(WETH).deposit{value: amountIn}();
    assert(IWETH(WETH).transfer(pairFor(_swap.path[0], _swap.path[1]), amountIn));
    uint balanceBefore = IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to);
    _swapSupportingFeeOnTransferTokens(_swap.path, _swap.to);
    require(
      IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to) - balanceBefore >= _swap.amount1,
      'MistXRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapETHForExactTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    require(_swap.path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    uint[] memory amounts = getAmountsIn(_swap.amount1, _swap.path);
    require(amounts[0] <= msg.value - _bribe, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(pairFor(_swap.path[0], _swap.path[1]), amounts[0]));
    _swapPath(amounts, _swap.path, _swap.to);

    // refund dust eth, if any
    if (msg.value - _bribe > amounts[0]) {
      (bool success, ) = msg.sender.call{value: msg.value - _bribe - amounts[0]}(new bytes(0));
      require(success, 'safeTransferETH: ETH transfer failed');
    }
  }

  function swapExactTokensForTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, pairFor(_swap.path[0], _swap.path[1]), _swap.amount0
    );
    uint balanceBefore = IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to);
    _swapSupportingFeeOnTransferTokens(_swap.path, _swap.to);
    require(
      IERC20(_swap.path[_swap.path.length - 1]).balanceOf(_swap.to) - balanceBefore >= _swap.amount1,
      'MistXRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapTokensForExactTokens(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    deposit(_bribe);

    uint[] memory amounts = getAmountsIn(_swap.amount0, _swap.path);
    require(amounts[0] <= _swap.amount1, 'MistXRouter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, pairFor(_swap.path[0], _swap.path[1]), amounts[0]
    );
    _swapPath(amounts, _swap.path, _swap.to);
  }

  function swapTokensForExactETH(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    require(_swap.path[_swap.path.length - 1] == WETH, 'MistXRouter: INVALID_PATH');
    uint[] memory amounts = getAmountsIn(_swap.amount0, _swap.path);
    require(amounts[0] <= _swap.amount1, 'MistXRouter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
        _swap.path[0], msg.sender, pairFor(_swap.path[0], _swap.path[1]), amounts[0]
    );
    _swapPath(amounts, _swap.path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    deposit(_bribe);
  
    // ETH after bribe must be swept to _to
    TransferHelper.safeTransferETH(_swap.to, amounts[amounts.length - 1] - _bribe);
  }

  function swapExactTokensForETH(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    require(_swap.path[_swap.path.length - 1] == WETH, 'MistXRouter: INVALID_PATH');
    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, pairFor(_swap.path[0], _swap.path[1]), _swap.amount0
    );
    _swapSupportingFeeOnTransferTokens(_swap.path, address(this));
    uint amountOut = IERC20(WETH).balanceOf(address(this));
    require(amountOut >= _swap.amount1, 'MistXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IWETH(WETH).withdraw(amountOut);

    deposit(_bribe);
  
    // ETH after bribe must be swept to _to
    TransferHelper.safeTransferETH(_swap.to, amountOut - _bribe);
  }

  /***********************
  + Library              +
  ***********************/

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    uint hashed = uint(keccak256(abi.encodePacked(
      hex'ff',
      factory,
      keccak256(abi.encodePacked(token0, token1)),
      initHash // init code hash
    )));
    pair = address(uint160(hashed));
  }

  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'MistXLibrary: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'MistXLibrary: ZERO_ADDRESS');
  }

  // fetches and sorts the reserves for a pair
  function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'MistXLibrary: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'MistXLibrary: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * (reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'MistXLibrary: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'MistXLibrary: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn * 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
    require(amountOut > 0, 'MistXLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'MistXLibrary: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn * amountOut * 1000;
    uint denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'MistXLibrary: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'MistXLibrary: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }

  /***********************
  + Support functions    +
  ***********************/

  function deposit(uint256 value) public payable {
    (bool sent, bytes memory data) = tipjar.call{value: value}(new bytes(0));
    require(sent, "Failed to send Ether");
  }

  function _swapSupportingFeeOnTransferTokens(
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = sortTokens(input, output);
      IUniswapV2Pair pair = IUniswapV2Pair(pairFor(input, output));
      uint amountInput;
      uint amountOutput;
      {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function _swapPath(
    uint[] memory amounts,
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? pairFor(output, path[i + 2]) : _to;
      IUniswapV2Pair(pairFor(input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  /***********************
  + Administration       +
  ***********************/

  modifier onlyManager() {
    require(managers[msg.sender] == true, "Only managers can call this");
    _;
  }

  function addManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = true;
  }

  function removeManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = false;
  }

  function changeTipjar(
    address _tipjar
  ) external onlyOwner {
    tipjar = _tipjar;
  }

  function rescueStuckETH(
    uint256 _amount,
    address _to
  ) external onlyManager {
    payable(_to).transfer(_amount);
  }

  function rescueStuckToken(
    address _tokenContract,
    uint256 _value,
    address _to
  ) external onlyManager {
    IERC20(_tokenContract).safeTransfer(_to, _value);
  }
}
