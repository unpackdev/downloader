// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./Address.sol";
import "./PuulAccessControl.sol";

contract Whitelist is PuulAccessControl {
  using Address for address;

  bool _startWhitelist;
  mapping (address => bool) _whitelist;
  mapping (address => bool) _blacklist;

  constructor () public {}

  modifier onlyWhitelist() {
    require(!_blacklist[msg.sender] && (!_startWhitelist || _whitelist[msg.sender]), "!whitelist");
    _;
  }

  function stopWhitelist() onlyHarvester external {
    _startWhitelist = false;
  }

  function startWhitelist() onlyHarvester external {
    _startWhitelist = true;
  }

  function addWhitelist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _whitelist[c] = true;
  }
  
  function removeWhitelist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _whitelist[c] = false;
  }
  
  function addBlacklist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _blacklist[c] = true;
  }
  
  function removeBlacklist(address c) onlyHarvester external {
    require(c != address(0), '!contract');
    _blacklist[c] = false;
  }
  
}
