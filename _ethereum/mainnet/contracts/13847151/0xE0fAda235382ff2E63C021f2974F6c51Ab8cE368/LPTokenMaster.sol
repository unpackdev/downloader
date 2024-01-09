// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "ILPTokenMaster.sol";
import "ILendingPair.sol";
import "ILendingController.sol";
import "SafeOwnable.sol";

contract LPTokenMaster is ILPTokenMaster, SafeOwnable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event NameChange(string _name, string _symbol);

  mapping (address => mapping (address => uint)) public override allowance;

  address public override underlying;
  address public lendingController;
  string  public constant name = "WILD-LP";
  string  public constant symbol = "WILD-LP";
  uint8   public constant override decimals = 18;
  bool    private initialized;

  modifier onlyOperator() {
    require(msg.sender == ILendingController(lendingController).owner(), "LPToken: caller is not an operator");
    _;
  }

  function initialize(address _underlying, address _lendingController) external override {
    require(initialized != true, "LPToken: already intialized");
    owner = msg.sender;
    underlying = _underlying;
    lendingController = _lendingController;
    initialized = true;
  }

  function transfer(address _recipient, uint _amount) external override returns(bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint _amount) external override returns(bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) external override returns(bool) {
    _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
    _transfer(_sender, _recipient, _amount);
    return true;
  }

  function lendingPair() external view override returns(address) {
    return owner;
  }

  function balanceOf(address _account) external view override returns(uint) {
    return ILendingPair(owner).supplySharesOf(underlying, _account);
  }

  function totalSupply() external view override returns(uint) {
    return ILendingPair(owner).totalSupplyShares(underlying);
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");

    ILendingPair(owner).transferLp(underlying, _sender, _recipient, _amount);

    emit Transfer(_sender, _recipient, _amount);
  }

  function _approve(address _owner, address _spender, uint _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }
}