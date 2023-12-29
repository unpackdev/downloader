// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Common.sol";

abstract contract CF_ERC20 is CF_Common {
  string internal _name;
  string internal _symbol;
  bytes32 internal _domainSeparator;
  bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  mapping(address => uint256) private _nonces;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balance[account];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowance[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);

    return true;
  }

  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, "Expired signature");

    unchecked {
      bytes32 digest = keccak256(abi.encodePacked(hex"1901", _domainSeparator, keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _nonces[owner]++, deadline))));
      address recoveredAddress = ecrecover(digest, v, r, s);

      require(recoveredAddress != address(0) && recoveredAddress == owner, "Invalid signature");
    }

    _approve(owner, spender, value);
  }

  function nonces(address owner) external view returns (uint256) {
    return _nonces[owner];
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparator;
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(address from, address to, uint256 amount) external returns (bool) {
    _spendAllowance(from, msg.sender, amount);
    _transfer(from, to, amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    unchecked {
      _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
    }

    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 currentAllowance = allowance(msg.sender, spender);

    require(currentAllowance >= subtractedValue, "Negative allowance");

    unchecked {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    _allowance[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function _spendAllowance(address owner, address spender, uint256 amount) internal {
    uint256 currentAllowance = allowance(owner, spender);

    require(currentAllowance >= amount, "Insufficient allowance");

    unchecked {
      _approve(owner, spender, currentAllowance - amount);
    }
  }

  function _transfer(address from, address to, uint256 amount) internal virtual {
    require(from != address(0) && to != address(0), "Transfer from/to zero address");
    require(_balance[from] >= amount, "Exceeds balance");

    if (amount > 0) {
      unchecked {
        _balance[from] -= amount;
        _balance[to] += amount;
      }
    }

    emit Transfer(from, to, amount);
  }
}
