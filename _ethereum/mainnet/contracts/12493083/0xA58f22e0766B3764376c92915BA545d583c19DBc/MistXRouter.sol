// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IUniswap.sol";
import "./IWETH.sol";
import "./MistXLibrary.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";


/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Gasless Router
contract MistXRouter {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  // The percentage we tip to the miners
  uint256 public bribePercent;

  // Owner of the contract and reciever of tips
  address public owner;

  // Managers are permissioned for critical functionality
  mapping (address => bool) public managers;

  address public immutable WETH;
  address public immutable factory;

  receive() external payable {}
  fallback() external payable {}

  constructor(
    address _WETH,
    address _factory
  ) {
    WETH = _WETH;
    factory = _factory;
    bribePercent = 99;

    owner = msg.sender;
    managers[msg.sender] = true;
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
    assert(IWETH(WETH).transfer(MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amountIn));
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
    uint[] memory amounts = MistXLibrary.getAmountsIn(factory, _swap.amount1, _swap.path);
    require(amounts[0] <= msg.value - _bribe, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    IWETH(WETH).deposit{value: amounts[0]}();
    assert(IWETH(WETH).transfer(MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amounts[0]));
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
      _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), _swap.amount0
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

    uint[] memory amounts = MistXLibrary.getAmountsIn(factory, _swap.amount0, _swap.path);
    require(amounts[0] <= _swap.amount1, 'MistXRouter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amounts[0]
    );
    _swapPath(amounts, _swap.path, _swap.to);
  }

  function swapTokensForExactETH(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    require(_swap.path[_swap.path.length - 1] == WETH, 'MistXRouter: INVALID_PATH');
    uint[] memory amounts = MistXLibrary.getAmountsIn(factory, _swap.amount0, _swap.path);
    require(amounts[0] <= _swap.amount1, 'MistXRouter: EXCESSIVE_INPUT_AMOUNT');
    TransferHelper.safeTransferFrom(
        _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), amounts[0]
    );
    _swapPath(amounts, _swap.path, address(this));
    IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    
    deposit(_bribe);
  
    // ETH after bribe must be swept to _to
    TransferHelper.safeTransferETH(_swap.to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    Swap calldata _swap,
    uint256 _bribe
  ) external payable {
    require(_swap.path[_swap.path.length - 1] == WETH, 'MistXRouter: INVALID_PATH');
    TransferHelper.safeTransferFrom(
      _swap.path[0], msg.sender, MistXLibrary.pairFor(factory, _swap.path[0], _swap.path[1]), _swap.amount0
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
  + Support functions    +
  ***********************/

  function deposit(uint256 value) public payable {
    require(value > 0, "Don't be stingy");
    uint256 bribe = (value * bribePercent) / 100;
    block.coinbase.transfer(bribe);
    payable(owner).transfer(value - bribe);
  }

  function _swapSupportingFeeOnTransferTokens(
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0,) = MistXLibrary.sortTokens(input, output);
      IUniswapV2Pair pair = IUniswapV2Pair(MistXLibrary.pairFor(factory, input, output));
      uint amountInput;
      uint amountOutput;
      {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = MistXLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < path.length - 2 ? MistXLibrary.pairFor(factory, output, path[i + 2]) : _to;
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
      (address token0,) = MistXLibrary.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 2 ? MistXLibrary.pairFor(factory, output, path[i + 2]) : _to;
      IUniswapV2Pair(MistXLibrary.pairFor(factory, input, output)).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
    }
  }

  /***********************
  + Administration       +
  ***********************/

  event OwnershipChanged(
    address indexed oldOwner,
    address indexed newOwner
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this");
    _;
  }

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

  function changeOwner(
    address _owner
  ) public onlyOwner {
    emit OwnershipChanged(owner, _owner);
    owner = _owner;
  }

  function changeBribe(
    uint256 _bribePercent
  ) public onlyManager {
    if (_bribePercent > 100) {
      revert("Split must be a valid percentage");
    }
    bribePercent = _bribePercent;
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
