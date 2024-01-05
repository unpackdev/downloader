// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Token.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract ERC20TokenFactory {

  address public uniV2Router;

  address[] public tokens;
  mapping (address => mapping (address => bool)) public tiers;
  mapping (address => address) public lastTier;

	constructor(address _uniV2Router) {
    uniV2Router = _uniV2Router;
	}

  function createToken(
    address owner,
    string memory name,
    string memory symbol,
    uint totalSupply,
    uint uniV2TokenLiquidity
  ) external returns (address token) {
    token = address(new ERC20Token(owner, name, symbol, totalSupply, uniV2TokenLiquidity));
    tokens.push(token);
  }

  function createUniV2TokenETHPairWithTiers(
    address token,
    address[] memory _tiers
  ) external payable returns (address pair) {
    require(ERC20Token(token).owner() == msg.sender && lastTier[token] == address(0), "Only token owner can call this once.");

    uint uniV2TokenLiquidity = ERC20Token(token).balanceOf(address(this));
    ERC20Token(token).approve(uniV2Router, uniV2TokenLiquidity);

    IUniswapV2Router01(uniV2Router).addLiquidityETH{ value: msg.value }
      (token, uniV2TokenLiquidity, uniV2TokenLiquidity, msg.value, msg.sender, block.timestamp + 86400);

    pair = IUniswapV2Factory(IUniswapV2Router01(uniV2Router).factory())
      .getPair(token, IUniswapV2Router01(uniV2Router).WETH());

    ERC20Token(token).lock(true);

    for (uint i = 0; i < _tiers.length; i++) {
     tiers[token][_tiers[i]] = true;
    }
    lastTier[token] = _tiers[_tiers.length - 1];
  }

  function swapETHForTokens(address token) external payable {
    require(tiers[token][msg.sender] == true, "Only tier can call this once.");

    ERC20Token(token).lock(false);

    address[] memory path = new address[](2);
    path[0] = IUniswapV2Router01(uniV2Router).WETH();
    path[1] = token;

    IUniswapV2Router01(uniV2Router).swapExactETHForTokens{ value: msg.value }
      (0, path, msg.sender, block.timestamp + 86400);

    tiers[token][msg.sender] = false;

    if(msg.sender != lastTier[token]) {
      ERC20Token(token).lock(true);
    }
  }

}
