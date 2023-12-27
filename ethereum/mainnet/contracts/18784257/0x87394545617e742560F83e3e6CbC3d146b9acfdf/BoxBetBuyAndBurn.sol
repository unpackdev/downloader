// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
  function WETH() external pure returns (address);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  )
  external payable returns (
    uint[] memory amounts
  );
}

contract BoxBetBuyAndBurn is Ownable {
  address public manager = 0x2045a2035253F672511a0E0a07A87D4B12FFC805;
  address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
  IERC20 public token;
  IUniswapV2Router public uniswapRouter;

  event Buy(uint256 amount);
  event Burn(uint256 amount);

  modifier onlyManager() {
    require(msg.sender == manager, "Not the manager");
    _;
  }

  constructor() {
    token = IERC20(0x33f289d91286535c47270C8479f6776Fb3AdEB3e);
    uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  }

  receive() external payable {}

  function setManager(address _manager) external onlyOwner {
    manager = _manager;
  }

  function buy(uint256 amount, uint256 minAmount) external onlyManager {
    address[] memory path = new address[](2);

    path[0] = uniswapRouter.WETH();
    path[1] = address(token);

    uniswapRouter.swapExactETHForTokens{ value: amount }(
      minAmount,
      path,
      address(this),
      block.timestamp
    );

    emit Buy(amount);
  }

  function burn() external {
    uint256 contractTokenBalance = token.balanceOf(address(this));
    token.transfer(burnAddress, contractTokenBalance);
    emit Burn(contractTokenBalance);
  }

  function withdraw() external onlyOwner {
    uint amount = address(this).balance;
    require(amount > 0, "Empty balance");

    (bool success, ) = owner().call{value: amount}("");
    require(success, "Transfer failed");
  }
}
