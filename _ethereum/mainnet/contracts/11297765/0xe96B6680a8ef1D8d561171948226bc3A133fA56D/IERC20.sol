//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.5;

interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);
}

contract ERC20 is IERC20 {
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowances;

  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    if (balances[msg.sender] < amount) {
      return false;
    }

    balances[msg.sender] -= amount;
    balances[recipient] += amount;
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    require(allowances[sender][msg.sender] >= amount, "No allowance");
    allowances[sender][msg.sender] -= amount;

    if (balances[sender] < amount) {
      return false;
    }

    balances[sender] -= amount;
    balances[recipient] += amount;
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    allowances[msg.sender][spender] = amount;
    return true;
  }
}

contract ERC20Mintable is ERC20 {
  function mint(address account, uint256 amount) external {
    balances[account] += amount;
  }
}
