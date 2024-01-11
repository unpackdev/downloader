// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

//
//                                 (((((((((((()                                 
//                              (((((((((((((((((((                              
//                            ((((((           ((((((                            
//                           (((((               (((((                           
//                         (((((/                 ((((((                         
//                        (((((                     (((((                        
//                      ((((((                       ((((()                      
//                     (((((                           (((((                     
//                   ((((((                             (((((                    
//                  (((((                                                        
//                ((((((                        (((((((((((((((                  
//               (((((                       (((((((((((((((((((((               
//             ((((((                      ((((((             (((((.             
//            (((((                      ((((((.               ((((((            
//          ((((((                     ((((((((                  (((((           
//         (((((                      (((((((((                   ((((((         
//        (((((                     ((((((.(((((                    (((((        
//       (((((                     ((((((   (((((                    (((((       
//      (((((                    ((((((      ((((((                   (((((      
//      ((((.                  ((((((          (((((                  (((((      
//      (((((                .((((((            ((((((                (((((      
//       ((((()            (((((((                (((((             ((((((       
//        .(((((((      (((((((.                   ((((((((     ((((((((         
//           ((((((((((((((((                         ((((((((((((((((           
//                .((((.                                    (((()         
//                                  
//                               attrace.com
//

import "./ERC20.sol";
import "./Ownable.sol";

// ATTR (12m vest) is a vesting contract to lock ATTR token and get 1 vesting token in exchange.
// The tokens from this contracts represent ownership to ATTR after the vesting time expired.
// The token can only be transferred to/from accounts which are valid vested token sources.
//
// More info: https://attrace.com
contract ATTRVested is ERC20, Ownable {
  uint16 public constant vestingMonths = 12; // Vesting time is 12 months

  // Any transfer from these addresses are considered as locked
  mapping(address => bool) public vestedTokenSources;

  // Reward token to be claimed (ATTR token)
  address public rewardToken;

  // Account time lock & vesting rules
  mapping(address => ClaimRule[]) public claimRules;

  event VestedTokenSourceAdded(address indexed sender, address indexed source);
  event VestedTokenSourceRemoved(address indexed sender, address indexed source);

  // Emitted whenever a transfer rule is configured
  event ClaimRuleConfigured(address addr, ClaimRule rule);
  event ClaimRuleRemoved(address addr, ClaimRule rule);

  // Create with ATTR token as reward token
  constructor(address _rewardToken) ERC20("ATTR (12m vest)", "ATTR (12m vest)") Ownable() {
    rewardToken = address(_rewardToken);
  }

  function deposit(uint256 _amount) external payable {
    IERC20(rewardToken).transferFrom(msg.sender, address(this), _amount);
    // Note: for non-ATTR tokens, we trust here the reward token, there is no guarantee the transfer actually happened.
    _mint(msg.sender, _amount);
  }

  // Claim unlocked tokens
  // Holders can claim using etherscan UI when interface is published.
  function claim() external {
    uint256 lockedToken = getVestedTokens(msg.sender);
    // Don't need to subtract last claim amount, because it is already burned from balance
    uint256 unlockedTokens = balanceOf(msg.sender) - lockedToken;
    require(balanceOf(msg.sender) >= unlockedTokens, "400: not enough reward tokens");

    // Burn wrapped token 
    _burn(msg.sender, unlockedTokens);

    // Send ATTR to msg.sender
    IERC20(rewardToken).transfer(msg.sender, unlockedTokens);
  }

  // Calculate how many tokens are still vested for a holder 
  function getVestedTokens(address from) public view returns (uint256) {
    uint256 totalLocked = 0;

    for (uint256 i = 0; i < claimRules[from].length; i++) {
      totalLocked += calcBalanceVestedOnRule(claimRules[from][i]);
    }
    return totalLocked;
  }

  // Helper to see unlocked tokens in generic contract tooling
  function getUnlockedTokens(address from) external view returns (uint256) {
    return balanceOf(from) - getVestedTokens(from);
  }

  // Only transfers from/to vested token sources and mint/burn is allowed.
  function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._afterTokenTransfer(from, to, amount);

    // If token is from vestedTokenSources, add the claimRule.
    // In ATTR flow the time of harvesting farm rewards starts the vesting period.
    if (vestedTokenSources[from] == true) {
      ClaimRule memory r = ClaimRule(uint128(amount), uint40(block.timestamp));
      claimRules[to].push(r);
      emit ClaimRuleConfigured(to, r);
    } else if (vestedTokenSources[to] == true) {
      // Allow funding token to farm
    } else if (to == address(0)) {
      // Allow burn
    } else if (from == address(0)) {
      // Allow mint
    } else {
      revert("401: token not tradeable");
    }
  }

  // -- Claim rules

  // The contract embeds transfer rules for project go-live and vesting.
  // claim rule describes the vesting rule a set of tokens is under since a relative time.
  // When the periods expire, user could call claim() to get the reward token.
  struct ClaimRule {
    // The number of tokens managed by the rule
    // Eg: when ecosystem adoption sends N ATTR to an exchange, then this will have 1000 tokens.
    uint128 tokens; // 16

    // Time when the rule went into effect
    // Eg: when ecosystem adoption wallet does a transfer to an exchange, the rule will receive block.timestamp.
    uint40 activationTime; // 5
  }

  // Calculate lockedBalance on a rule
  function calcBalanceVestedOnRule(ClaimRule storage rule) private view returns (uint256) {
    uint256 vestingStart = rule.activationTime;
    uint256 unlockedSlices = 0;
    for(uint256 i = 0; i < vestingMonths; i++) {
      if(block.timestamp >= (vestingStart + ((i + 1)* 30 days))) {
        unlockedSlices++;
      }
    }

    // If all months are vested, return 0 to ensure all tokens are sent back
    if(vestingMonths == unlockedSlices) {
      return 0;
    }

    // Send back the amount of vested tokens
    return (rule.tokens - ((rule.tokens / vestingMonths) * unlockedSlices));
  }

  // -- Owner management methods

  function addVestedTokenSources(address[] calldata sources) external onlyOwner {
    for (uint256 i = 0; i < sources.length; i++) {
      vestedTokenSources[sources[i]] = true;
      emit VestedTokenSourceAdded(msg.sender, sources[i]);
    }
  }

  function removeVestedTokenSources(address[] calldata sources) external onlyOwner {
    for (uint256 i = 0; i < sources.length; i++) {
      delete vestedTokenSources[sources[i]];
      emit VestedTokenSourceRemoved(msg.sender, sources[i]);
    }
  }

  function removeClaimRules(address addr, uint256 amount) external onlyOwner {
    if(amount > claimRules[addr].length) {
      amount = claimRules[addr].length;
    }

    // Start deleting from the end
    uint256 stop = claimRules[addr].length - amount;
    for(uint256 i = claimRules[addr].length; i > stop; i--) {
      emit ClaimRuleRemoved(addr, claimRules[addr][i - 1]);
      claimRules[addr].pop();
    }
  }
}
