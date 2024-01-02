// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract TokenLock {

  // ERC20 basic token contract being held
  IERC20 private _token;

  // beneficiary of tokens after they are released
  address private _beneficiary;

  // timestamp when token release is enabled
  uint256 private _releaseTime;

  // generator of the tokenLock
  address private _owner;

  event UnLock(address _receiver, uint256 _amount);
  event Retrieve(address _receiver, uint256 _amount);

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  constructor(IERC20 token, address beneficiary, address owner, uint256 releaseTime) {
    _owner = owner;
    _token = token;
    _beneficiary = beneficiary;
    _releaseTime = releaseTime;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @return the token being held.
   */
  function token() public view returns (IERC20) {
    return _token;
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiary() public view returns (address) {
    return _beneficiary;
  }

  /**
   * @return the time when the tokens are released.
   */
  function releaseTime() public view returns (uint256) {
    return _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    require(block.timestamp >= _releaseTime);

    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0);

    require(_token.transfer(_beneficiary, amount), "Token transfer failed");
    emit UnLock(_beneficiary, amount);
  }

  /**
   * @notice Retrieve tokens held by timelock to generator(owner).
   */
  function retrieve() onlyOwner public {
    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0);

    require(_token.transfer(_owner, amount), "Token transfer failed");
    emit Retrieve(_owner, amount);
  }
}