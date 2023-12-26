/*

    _                           
  _| |_ _____ ___ __   __ _____ 
 /    _|_   _|   )  \ /  |  ___)
( (| |_  | |  | ||   v   | |_   
 \_    \ | |  | || |\_/| |  _)  
  _| |) )| |  | || |   | | |___ 
 (_   _/ |_| (___)_|   |_|_____)
   |_|                          
                                
        - DEGEN CALENDAR -

Website:        https://decal.wtf
Twitter(X):     https://twitter.com/decalwtf
Telegram Chat:  https://t.me/decalwtf

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable2Step.sol";

contract TimeToken is ERC20, Ownable2Step {
  address public TEAM_WALLET;
  mapping(address => bool) public TAX_WHITELIST;
  mapping(address => bool) public AMM_PAIRS;

  constructor(
    address initialOwner,
    address teamWallet
  ) ERC20("Degen Calendar", "TIME") Ownable(initialOwner) {
    TEAM_WALLET = teamWallet;
    TAX_WHITELIST[teamWallet] = true;
    TAX_WHITELIST[initialOwner] = true;

    _mint(initialOwner, 1000000 * 10 ** decimals());
  }

  function setTeamWallet(address teamWallet) external onlyOwner {
    TAX_WHITELIST[TEAM_WALLET] = false;
    TEAM_WALLET = teamWallet;
    TAX_WHITELIST[teamWallet] = true;
  }

  function setTaxWhitelist(address account, bool whitelist) external onlyOwner {
    TAX_WHITELIST[account] = whitelist;
  }

  function setAmmPair(address pair, bool add) external onlyOwner {
    AMM_PAIRS[pair] = add;
  }

  function _update(
    address from,
    address to,
    uint256 value
  ) internal virtual override {
    // No tax for whitelisted accounts
    if (TAX_WHITELIST[from] || TAX_WHITELIST[to]) {
      super._update(from, to, value);
      return;
    }

    // No tax between pools (allow multiple pools to be used at once)
    if (AMM_PAIRS[from] && AMM_PAIRS[to]) {
      super._update(from, to, value);
      return;
    }

    // Tax if either sender or recipient is a pool (i.e. buying or selling)
    if (AMM_PAIRS[from] || AMM_PAIRS[to]) {
      uint tax = (value * 5) / 100; // 5% tax

      super._update(from, to, value - tax);
      super._update(from, TEAM_WALLET, tax);
      return;
    }

    // No tax for regular transfers
    super._update(from, to, value);
  }
}
