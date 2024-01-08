// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";

// The ATTRToken is the Attrace utility token.
// More info: https://attrace.com
//
// We keep the contract upgradeable during development to make sure we can evolve and implement gas optimizations later on.
//
// Upgrade strategy towards DAO:
// -  Pre-DAO: the token is managed and improved by the Attrace project.
// -  When DAO is achieved: the token will become owned by the DAO contracts, or if the DAO decides to lock the token, then it can do so by transferring ownership to a contract which can't be upgraded.
contract ATTRToken is ERC20Upgradeable {
  // Accounts which can transfer out in the pre-listing period
  mapping(address => bool) private _preListingAddrWL;

  // Timestamp when rules are disabled, once this time is reached, this is irreversible
  uint64 private _wlDisabledAt;

  // Who can modify _preListingAddrWL and _wlDisabledAt (team doing the listing).
  address private _wlController;

  // Account time lock & vesting rules
  mapping(address => TransferRule) public transferRules;

  // Emitted whenever a transfer rule is configured
  event TransferRuleConfigured(address addr, TransferRule rule);  

  function initialize(address preListWlController) public initializer {
    __ERC20_init("Attrace", "ATTR");
    _mint(msg.sender, 10 ** 27); // 1000000000000000000000000000 aces, 1,000,000,000 ATTR
    _wlController = address(preListWlController);
    _wlDisabledAt = 1624399200; // June 23 2021
  }

  // Hook into openzeppelin's ERC20Upgradeable flow to support golive requirements
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    // When not yet released, verify that the sender is white-listed.
    if(_wlDisabledAt > block.timestamp) {
      require(_preListingAddrWL[from] == true, "not yet tradeable");
    }

    // If we reach this, the token is already released and we verify the transfer rules which enforce locking and vesting.
    if(transferRules[from].tokens > 0) {
      uint lockedTokens = calcBalanceLocked(from);
      uint balanceUnlocked = super.balanceOf(from) - lockedTokens;
      require(amount <= balanceUnlocked, "transfer rule violation");
    }

    // If we reach this, the transfer is successful.
    // Check if we should lock/vest the recipient of the tokens.
    if(transferRules[from].outboundVestingMonths > 0 || transferRules[from].outboundTimeLockMonths > 0) {
      // We don't support multiple rules, so recipient should not have vesting rules yet.
      require(transferRules[to].tokens == 0, "unsupported");
      transferRules[to].timeLockMonths = transferRules[from].outboundTimeLockMonths;
      transferRules[to].vestingMonths = transferRules[from].outboundVestingMonths;
      transferRules[to].tokens = uint96(amount);
      transferRules[to].activationTime = uint40(block.timestamp);
    }
  }

  // To support listing some addresses can be allowed transfers pre-listing.
  function setPreReleaseAddressStatus(address addr, bool status) public {
    require(_wlController == msg.sender);
    _preListingAddrWL[addr] = status;
  }

  // Once pre-release rules are disabled, rules remain disabled
  // While not expected to be used, in case of need (to support optimal listing), the team can control the time the token becomes tradeable.
  function setNoRulesTime(uint64 disableTime) public {
    require(_wlController == msg.sender); // Only controller can 
    require(_wlDisabledAt > uint64(block.timestamp)); // Can not be set anymore when rules are already disabled
    require(disableTime > uint64(block.timestamp)); // Has to be in the future
    _wlDisabledAt = disableTime;
  }

  // ---- LOCKING & VESTING RULES

  // The contract embeds transfer rules for project go-live and vesting.
  // Vesting rule describes the vesting rule a set of tokens is under since a relative time.
  // This is gas-optimized and doesn't require the user to do any form of release() calls. 
  // When the periods expire, tokens will become tradeable.
  struct TransferRule {
    // The number of 30-day periods timelock this rule enforces.
    // This timelock starts from the rule activation time.
    uint16 timeLockMonths; // 2

    // The number of 30-day periods vesting this rule enforces.
    // This period starts after the timelock period has expired.
    // The number of tokens released in every cycle equals rule.tokens/vestingMonths.
    uint16 vestingMonths; // 2

    // The number of tokens managed by the rule
    // Eg: when ecosystem adoption sends N ATTR to an exchange, then this will have 1000 tokens.
    uint96 tokens; // 12

    // Time when the rule went into effect
    // When the rule is 0, then the _wlDisabledAt time is used (time of listing).
    // Eg: when ecosystem adoption wallet does a transfer to an exchange, the rule will receive block.timestamp.
    uint40 activationTime; // 5

    // Rules to apply to outbound transfers.
    // Eg: ecosystem adoption wallet can do transfers, but all received assets will be under locked rules.
    // When the recipient already has a vesting rule, the transfer will fail.
    // rule.activationTime and rule.tokens will be set by the transfer caller.
    uint16 outboundTimeLockMonths; // 2
    uint16 outboundVestingMonths; // 2
  }

  // Calculate how many tokens are still locked for a holder 
  function calcBalanceLocked(address from) private view returns (uint) {
    // When no activation time is defined, the moment of listing is used.
    uint activationTime = (transferRules[from].activationTime == 0 ? _wlDisabledAt : transferRules[from].activationTime);

    // First check the time lock
    uint secondsLocked;
    if(transferRules[from].timeLockMonths > 0) {
      secondsLocked = (transferRules[from].timeLockMonths * (30 days));
      if(activationTime+secondsLocked >= block.timestamp) {
        // All tokens are still locked
        return transferRules[from].tokens;
      }
    }

    // If no time lock, then calculate how much is unlocked according to the vesting rules.
    if(transferRules[from].vestingMonths > 0) {
      uint vestingStart = activationTime + secondsLocked;
      uint unlockedSlices = 0;
      for(uint i = 0; i < transferRules[from].vestingMonths; i++) {
        if(block.timestamp >= (vestingStart + (i * 30 days))) {
          unlockedSlices++;
        }
      }
      // If all months are vested, return 0 to ensure all tokens are sent back
      if(transferRules[from].vestingMonths == unlockedSlices) {
        return 0;
      }

      // Send back the amount of locked tokens
      return (transferRules[from].tokens - ((transferRules[from].tokens / transferRules[from].vestingMonths) * unlockedSlices));
    }

    // No tokens are locked
    return 0;
  }

  // The contract enforces all vesting and locking rules as desribed on https://attrace.com/community/attr-token/#distribution
  // We don't lock tokens into another contract, we keep them allocated to the respective account, but with a locking rule on top of it.
  // When the last vesting rule expires, checking the vesting rules is ignored automatically and overall gas off the transfers lowers with an SLOAD cost.
  function setTransferRule(address addr, TransferRule calldata rule) public {
    require(_wlDisabledAt > uint64(block.timestamp)); // Can only be set before listing
    require(_wlController == msg.sender); // Only the whitelist controller can set rules before listing

    // Validate the rule
    require(
      // Either a rule has a token vesting/lock
      (rule.tokens > 0 && (rule.vestingMonths > 0 || rule.timeLockMonths > 0))
      // And/or it has an outbound rule
      || (rule.outboundTimeLockMonths > 0 || rule.outboundVestingMonths > 0), 
      "invalid rule");

    // Store the rule
    // Rules are allowed to have an empty activationTime, then listing moment will be used as activation time.
    transferRules[addr] = rule;

    // Emit event that a rule was set
    emit TransferRuleConfigured(addr, rule);
  }

  function getLockedTokens(address addr) public view returns (uint256) {
    return calcBalanceLocked(addr);
  }

  // Batch route to set many rules at once
  function batchSetTransferRules(address[] calldata addresses, TransferRule[] calldata rules) public {
    require(_wlDisabledAt > uint64(block.timestamp)); // Can only be set before listing
    require(_wlController == msg.sender); // Only the whitelist controller can set rules before listing
    require(addresses.length != 0);
    require(addresses.length == rules.length);
    for(uint i = 0; i < addresses.length; i++) {
      setTransferRule(addresses[i], rules[i]);
    }
  }
}
