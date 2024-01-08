// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IBury.sol";
import "./IWETH9.sol";

contract xShibBot {
  address payable private controller;

  IWETH9 public weth;
  IERC20 public shib;
  IBury public xshib;
  IUniswapV2Router02 public router;

  constructor(address payable _controller, address _router, address _shib, address _xshib) {
    require(_controller != address(0), "_controller is zero address");
    require(_router != address(0), "_router is zero address");
    require(_shib != address(0), "_shib is zero address");
    require(_xshib != address(0), "_xshib is zero address");
    controller = _controller;
    shib = IERC20(_shib);
    xshib = IBury(_xshib);
    router = IUniswapV2Router02(_router);
    weth = IWETH9(router.WETH());
  }

  event Executed(uint inETH, uint outETH);
  event Received(address sender, uint amount);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function withdrawEth(uint256 amount) public {
    require(msg.sender == controller, "only controller can call this function");
    require(address(this).balance >= amount, "insufficient amount");
    controller.transfer(amount);
  }

  function withdrawToken(address token, uint256 amount) public {
    require(msg.sender == controller, "only controller can call this function");
    IERC20 _token = IERC20(token);
    require(_token.balanceOf(address(this)) >= amount, "insufficient amount");
    _token.transfer(controller, amount);
  }

  function buyXShib(uint256 minAmount, uint deadline) public payable returns (uint256) {
    require(msg.sender == controller, "only controller can call this function");
    address[] memory path = new address[](2);
    path[0] = address(weth);
    path[1] = address(xshib);
    uint[] memory amounts = router.swapExactETHForTokens{value:msg.value}(minAmount, path, address(this), deadline);
    return amounts[0];
  }

  function sellShib(uint256 inAmount, uint256 minOutAmount, uint deadline) public returns (uint256) {
    require(msg.sender == controller, "only controller can call this function");
    address[] memory path = new address[](2);
    path[0] = address(shib);
    path[1] = address(weth);
    shib.approve(address(router), inAmount);
    uint[] memory amounts = router.swapExactTokensForETH(inAmount, minOutAmount, path, address(this), deadline);
    return amounts[0];
  }

  function swapXShibToShib(uint256 amount) public returns (uint256) {
    require(msg.sender == controller, "only controller can call this function");
    xshib.approve(address(router), amount);
    xshib.leave(amount);
    return amount * xshib.balanceOf(address(this)) / xshib.totalSupply();
  }

  function changeController(address payable _controller) public {
    require(msg.sender == controller, "only controller can call this function");
    controller = _controller;
  }

  function exec(uint256 minXShib, uint256 minOutETH, uint deadline) public payable returns (uint256, uint256, uint256) {
    require(msg.sender == controller, "only controller can call this function");
    buyXShib(minXShib, deadline);
    uint256 xshibAmount = xshib.balanceOf(address(this));
    swapXShibToShib(xshibAmount);
    uint256 shibAmount = shib.balanceOf(address(this));
    sellShib(shibAmount, minOutETH, deadline);
    uint256 retETH = address(this).balance;
    controller.transfer(retETH);
    emit Executed(msg.value, retETH);
    return (xshibAmount, shibAmount, retETH);
  }
}
