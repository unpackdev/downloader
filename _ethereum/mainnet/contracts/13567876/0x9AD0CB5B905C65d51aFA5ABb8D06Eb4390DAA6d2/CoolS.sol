// SPDX-License-Identifier: MIT
// https://secretnftsociety.com

// It was all a meme.
//
// Cool S points have no inherent utility
// or value. They can be exchanged / renamed
// for other types of meaningless "cool points."

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./BokkyPooBahsRedBlackTreeLibrary.sol";

contract CoolSToken is ERC20 {
  address private _minter;
  event NewToken(address indexed _address, string indexed _name, string indexed _symbol);

  constructor(
    string memory _name,
    string memory _symbol,
    address __minter
  ) ERC20(_name, _symbol) {
    _minter = __minter;
  }

  /* Increment tokens. */
  function mint(address _to, uint256 _amount) public virtual {
    require(msg.sender == _minter, "Unauthorized.");
    require(_amount > 0, "Amount required.");
    _mint(_to, _amount);
  }

  /* Decrement tokens. */
  function burn(address _to, uint256 _amount) public {
    require(msg.sender == _minter, "Unauthorized.");
    require(_amount > 0, "Amount required.");
    _burn(_to, _amount);
  }
}

contract CoolS is CoolSToken {
  using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
  BokkyPooBahsRedBlackTreeLibrary.Tree tree;

  address private _minter;
  address[] _tokens;
  mapping(uint => uint[]) _values;
  mapping(address => uint) _keys;
  mapping(uint => uint) _keyIndices;

  constructor(
    string memory _name,
    string memory _symbol,
    address __minter
  ) CoolSToken(_name, _symbol, __minter) {
    _tokens.push(address(this));
    uint key = _tokens.length;
    _keys[address(this)] = key;
    _minter = __minter;
  }

  /* Get total tokens created. */
  function totalTokens() public view returns (uint) {
    return _tokens.length;
  }

  /* Get token address at index. */
  function getToken(uint _idx) public view returns (address) {
    return _tokens[_idx];
  }

  /* BST queries */
  function top() public view returns (uint) {
    // Token key with most points
    return tree.last();
  }

  function next(uint _idx) public view returns (uint) {
    // Next key with more points than provided index.
    return tree.prev(_idx);
  }

  function prev(uint _idx) public view returns (uint) {
    // Prev key with less points than provided index.
    return tree.next(_idx);
  }

  // Gets the number of tokens at a supply level.
  function totalTokensWithSupply(uint _totalSupply) public view returns (uint) {
    return _values[_totalSupply].length;
  }

  // Gets the token at the total supply index.
  function getTokenAtSupplyIndex(uint _totalSupply, uint _idx) public view returns (uint) {
    require(_values[_totalSupply].length > _idx && _values[_totalSupply][_idx] > 0, "Not found.");
    return _values[_totalSupply][_idx] - 1;
  }

  /* Create a new Cool S backed ERC20 token. */
  function newToken(string memory _name, string memory _symbol) public returns (address) {
    CoolSToken child = new CoolSToken(_name, _symbol, address(this));
    address childAddress = address(child);
    emit NewToken(childAddress, _name, _symbol);
    _tokens.push(childAddress);
    _keys[childAddress] = _tokens.length;

    return childAddress;
  }

  /* Sort top tokens in BST. */
  function _updateValues(uint _supplyBefore, uint _supplyAfter, uint _key) private {
    uint idx = _keyIndices[_key];
    if (idx > 0) {
      if (_values[_supplyBefore].length > 1) {
        _values[_supplyBefore][idx-1] = _values[_supplyBefore].length - 1;
      }
      if (_values[_supplyBefore].length > 0) {
        _values[_supplyBefore].pop();
      }
      if (_values[_supplyBefore].length == 0 && tree.exists(_supplyBefore)) tree.remove(_supplyBefore);
    }
    if (_supplyAfter > 0) {
      _values[_supplyAfter].push(_key);
      _keyIndices[_key] = _values[_supplyAfter].length;
      if (!tree.exists(_supplyAfter)) tree.insert(_supplyAfter);
    }
  }

  /* Mint Cool S for artwork's "cool points" score. */
  function mint(address _to, uint256 _amount) public override {
    require(msg.sender == _minter, "Unauthorized.");
    uint supplyCoolSBefore = totalSupply();
    uint supplyCoolSAfter = supplyCoolSBefore + _amount;
    uint keyCoolS = _keys[address(this)];
    _mint(_to, _amount);
    _updateValues(supplyCoolSBefore, supplyCoolSAfter, keyCoolS);
  }

  /* Exchange Cool S for another type of "cool points." */
  function mintToken(address _to, address _token, uint _amount) public {
    CoolSToken t = CoolSToken(_token);
    uint supplyCoolSBefore = totalSupply();
    uint supplyCoolSAfter = supplyCoolSBefore - _amount;
    uint keyCoolS = _keys[address(this)];
    _burn(msg.sender, _amount);
    _updateValues(supplyCoolSBefore, supplyCoolSAfter, keyCoolS);

    uint supplyTokenBefore = t.totalSupply();
    uint supplyTokenAfter = supplyTokenBefore + _amount;
    uint keyToken = _keys[_token];
    t.mint(_to, _amount);
    _updateValues(supplyTokenBefore, supplyTokenAfter, keyToken);
  }

  /* Return points back to standard Cool S points. */
  function returnToken(address _to, address _token, uint _amount) public {
    CoolSToken t = CoolSToken(_token);
    uint supplyTokenBefore = t.totalSupply();
    uint supplyTokenAfter = supplyTokenBefore - _amount;
    uint keyToken = _keys[_token];
    t.burn(msg.sender, _amount);
    _updateValues(supplyTokenBefore, supplyTokenAfter, keyToken);

    uint supplyCoolSBefore = totalSupply();
    uint supplyCoolSAfter = supplyCoolSBefore + _amount;
    uint keyCoolS = _keys[address(this)];
    _mint(_to, _amount);
    _updateValues(supplyCoolSBefore, supplyCoolSAfter, keyCoolS);
  }
}
