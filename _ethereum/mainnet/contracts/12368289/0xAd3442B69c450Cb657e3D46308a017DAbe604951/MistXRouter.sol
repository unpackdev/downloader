// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./IMistXJar.sol";
import "./IUniswap.sol";
import "./SafeERC20.sol";


/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Gasless Router
contract MistXRouter {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  IMistXJar MistXJar;

  address public owner;
  mapping (address => bool) public managers;

  receive() external payable {}
  fallback() external payable {}

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
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value - _bribe}(
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );
  }

  function swapETHForExactTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    _router.swapETHForExactTokens{value: msg.value - _bribe}(
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );

    // Refunded ETH needs to be swept from router to user address
    (bool success, ) = payable(_swap.to).call{value: address(this).balance}("");
    require(success);
  }

  function swapExactTokensForTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount0);
    from.safeIncreaseAllowance(address(_router), _swap.amount0);

    _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );
  }

  function swapTokensForExactTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount1);
    from.safeIncreaseAllowance(address(_router), _swap.amount1);

    _router.swapTokensForExactTokens(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );

    from.safeTransfer(msg.sender, from.balanceOf(address(this)));
  }

  function swapTokensForExactETH(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount1);
    from.safeIncreaseAllowance(address(_router), _swap.amount1);

    _router.swapTokensForExactETH(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      address(this),
      _swap.deadline
    );

    MistXJar.deposit{value: _bribe}();
  
    // ETH after bribe must be swept to _to
    (bool success, ) = payable(_swap.to).call{value: address(this).balance}("");
    require(success);

    // Left-over from tokens must be swept to _to
    from.safeTransfer(msg.sender, from.balanceOf(address(this)));
  }

  function swapExactTokensForETH(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount0);
    from.safeIncreaseAllowance(address(_router), _swap.amount0);

    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      address(this),
      _swap.deadline
    );

    MistXJar.deposit{value: _bribe}();
  
    // ETH after bribe must be swept to _to
    (bool success, ) = payable(_swap.to).call{value: address(this).balance}("");
    require(success);
  }

  /***********************
  + Administration       +
  ***********************/

  event OwnershipChanged(
    address indexed oldOwner,
    address indexed newOwner
  );

  constructor(
    address _mistJar
  ) {
    MistXJar = IMistXJar(_mistJar);
    owner = msg.sender;
    managers[msg.sender] = true;
  }

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

  function changeJar(
    address _mistJar
  ) public onlyManager {
    MistXJar = IMistXJar(_mistJar);
  }

  function changeOwner(
    address _owner
  ) public onlyOwner {
    emit OwnershipChanged(owner, _owner);
    owner = _owner;
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
