// hevm: flattened sources of src/TokenBuy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract TokenBuy is Ownable {
  address public token;
  address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  IUniswapV2Pair public uniswapPair;
  address[] public buyPath;

  mapping (address => bool) whitelist;

  constructor(address _token) {
    token = _token;
    buyPath = new address[](2);
    buyPath[0] = IUniswapV2Router02(uniswapRouter).WETH();
    buyPath[1] = token;

    IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory());
    uniswapPair = IUniswapV2Pair(factory.getPair(_token, IUniswapV2Router02(uniswapRouter).WETH()));

    whitelist[msg.sender] = true;
  }

  receive() external payable {}

  function withdrawEth() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function setWhitelist(address[] memory _whitelist) external onlyOwner {
    for (uint i = 0; i < _whitelist.length; i++) {
      whitelist[_whitelist[i]] = true;
    }
  }

  function buyToken(uint256 _percentPerBuy, address _recipient) external {
    require(whitelist[msg.sender], "!whitelist");
    uint256 totalSupply = IERC20(token).totalSupply();
    for (uint i = 0; i < 2; i++) {
      uint256[] memory amountsIn = IUniswapV2Router02(uniswapRouter).getAmountsIn(totalSupply * _percentPerBuy / 10000, buyPath);
      if (address(this).balance >= amountsIn[0]) {
        IUniswapV2Router02(uniswapRouter).swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountsIn[0]}(0, buyPath, _recipient, block.timestamp + 900);
      }
    }
  }

  function updateToken(address _token) external onlyOwner {
    token = _token;
    buyPath = new address[](2);
    buyPath[0] = IUniswapV2Router02(uniswapRouter).WETH();
    buyPath[1] = token;

    IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Router02(uniswapRouter).factory());
    uniswapPair = IUniswapV2Pair(factory.getPair(_token, IUniswapV2Router02(uniswapRouter).WETH()));
  }
}
