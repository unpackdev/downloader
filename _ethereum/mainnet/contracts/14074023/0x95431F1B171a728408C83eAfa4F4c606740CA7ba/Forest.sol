// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LotteryBox.sol";
import "./HunterHound.sol";
import "./Prey.sol";

contract Forest is LotteryBox {

  event StakeEvent(address indexed operator, uint256[][] pairs);
  event ClaimEvent(address indexed operator, uint256 receiveProfit, uint256 totalProfit);
  event UnstakeEvent(address indexed operator, address indexed recipient, uint256 indexed tokenId, uint256 receiveProfit, uint256 totalProfit);

  struct Stake{
    uint timestamp;
    bool hunter;
    uint hounds;
    uint alpha;
    uint256[] tokenIds;
  }
  uint constant GAMBLE_CLAIM = 1;
  uint constant GAMBLE_UNSTAKE = 2;
  uint constant GAMBLE_UNSTAKE_GREDDY = 3;
  // action 1:claim 2:unstake 3:unstake with greddy
  struct Gamble {
    uint action;
    uint blockNumber;
  }

  // the minimum amount of $PREY tokens to own before unstaking
  uint constant MINIMUN_UNSTAKE_AMOUNT = 20000 ether; 
  // every hound receives 10,000 tokens a day
  uint constant PROFIT_PER_SINGLE_HOUND = 10000 ether;

  // the total profit
  uint constant TOTAL_PROFIT = 2400000000 ether;

  // the total claimed $PREY including burned in the game
  uint internal totalClaimed; 
  // the total bunred $PREY
  uint internal totalBurned;

  // staked list
  mapping(address => Stake[]) internal stakes;

  // record original owner of the token
  mapping(uint => address) internal tokenOwners;

  // record tokenId of the hunters who have corresponding alpha score
  mapping(uint256 => uint256[]) internal hunterAlphaMap;

  // record index of hunter tokenId in `hunterAlphaMap`
  mapping(uint256 => uint256) internal hunterTokenIndices;

  // staked hounds count
  uint internal houndStaked;
  // staked hunters count
  uint internal hunterStaked;
  // the number of hounds adopted by other hunters
  uint internal houndsCaptured;

  mapping(address => Gamble) internal gambleRequests;


  /**
   * When there is a gamble request
   */
  modifier whenGambleRequested() {
      require(gambleRequests[msg.sender].blockNumber == 0, "Unstake or claim first");
      _;
  }

  /**
   * stake submitted tokens group and transfer to the staking contract
   */
  function _stake(address owner, uint256[][] calldata pairs, HunterHound hh) internal whenGambleRequested {

    require(pairs.length > 0, "Tokens empty");
    require(totalClaimed < TOTAL_PROFIT, "No profit");

    uint totalHunter = 0;
    uint totalHounds = 0;
    
    (totalHunter, totalHounds) = _storeStake(owner, pairs, hh);

    hunterStaked = hunterStaked + totalHunter;
    houndStaked = houndStaked + totalHounds;

    // transfer token
    for (uint256 i = 0; i < pairs.length; i++) {
      for (uint256 j = 0; j < pairs[i].length; j++) {
        uint256 tokenId = pairs[i][j];
        hh.transferByController(owner, address(this), tokenId);
      }
    }
    emit StakeEvent(owner, pairs);
  }

  /**
   * store staking groups
   */
  function _storeStake(address owner, uint256[][] calldata paris, HunterHound hh) private returns(uint totalHunter, uint totalHounds) {
    for (uint256 i = 0; i < paris.length; i++) {
      uint256[] calldata tokenIds = paris[i];
      uint hunters;
      uint hounds;
      uint256 hunterAlpha;
      uint hunterIndex = 0;
      (hunters, hounds, hunterAlpha, hunterIndex) = _storeTokenOwner(owner, tokenIds, hh);
      require(hounds > 0 && hounds <= 3, "Must have 1-3 hound in a pair");
      require(hunters <= 1, "Only be one hunter in a pair");
      
      // in order to select a hound, a hunter must be placed in the rear of the group
      require(hunters == 0 || hunterIndex == (tokenIds.length-1), "Hunter must be last one");
      totalHunter = totalHunter + hunters;
      totalHounds = totalHounds + hounds;
      stakes[owner].push(Stake({
        timestamp: block.timestamp,
        hunter: hunters > 0,
        hounds: hounds,
        alpha: hunterAlpha,
        tokenIds: tokenIds
      }));

      if (hunters > 0) {
        uint256 hunterTokenId = tokenIds[tokenIds.length-1];
        hunterTokenIndices[hunterTokenId] = hunterAlphaMap[hunterAlpha].length;
        hunterAlphaMap[hunterAlpha].push(hunterTokenId);
      }
    }
  }

  /**
   * record token owner in order to return $PREY token correctly to the owner in case of unstaking
   */
  function _storeTokenOwner(address owner, uint[] calldata tokenIds, HunterHound hh) private 
    returns(uint hunters,uint hounds,uint hunterAlpha,uint hunterIndex) {
    for (uint256 j = 0; j < tokenIds.length; j++) {
        uint256 tokenId = tokenIds[j];
        require(tokenOwners[tokenId] == address(0), "Unstake first");
        require(hh.ownerOf(tokenId) == owner, "Not your token");
        bool isHunter;
        uint alpha;
        (isHunter, alpha) = hh.isHunterAndAlphaByTokenId(tokenId);

        if (isHunter) {
          hunters = hunters + 1;
          hunterAlpha = alpha;
          hunterIndex = j;
        } else {
          hounds = hounds + 1;
        }
        tokenOwners[tokenId] = owner;
      }
  }
  
  /**
   * calculate and claim staked reward, if the players chooses to gamble, there's a probability to lose all rewards
   */
  function _claim(address owner, Prey prey) internal {

    uint requestBlockNumber = gambleRequests[owner].blockNumber;
    uint totalProfit = _claimProfit(owner, false);
    uint receiveProfit;
    if (requestBlockNumber > 0) {
      require(gambleRequests[owner].action == GAMBLE_CLAIM, "Unstake first");
      uint random = openBox(requestBlockNumber);
      uint percent = percentNumber(random);
      if (percent <= 50) {
        receiveProfit = 0;
      } else {
        receiveProfit = totalProfit;
      }
      delete gambleRequests[owner];
    } else {
      receiveProfit = (totalProfit * 80) / 100;
    }

    if (receiveProfit > 0) {
      prey.mintByForest(owner, receiveProfit);
    }
    if (totalProfit - receiveProfit > 0) {
      totalBurned = totalBurned + (totalProfit - receiveProfit);
    }
    emit ClaimEvent(owner, receiveProfit, totalProfit);
  }

  /**
   * calculate stake rewards, reset timestamp in case of claiming
   */
  function _collectStakeProfit(address owner, bool unstake) private returns (uint profit) {
    for (uint i = 0; i < stakes[owner].length; i++) {
      Stake storage stake = stakes[owner][i];
      
      profit = profit + _caculateProfit(stake);
      if (!unstake) {
        stake.timestamp = block.timestamp;
      }
    }
    
    require(unstake == false || profit >= MINIMUN_UNSTAKE_AMOUNT, "Minimum claim is 20000 PREY");
  }
  
  /**
   * return claimable staked rewards, update `totalClaimed`
   */
  function _claimProfit(address owner, bool unstake) private returns (uint) {
    uint profit = _collectStakeProfit(owner, unstake);
    
    if (totalClaimed + profit > TOTAL_PROFIT) {
      profit = TOTAL_PROFIT - totalClaimed;
    }
    totalClaimed = totalClaimed + profit;
    
    return profit;
  }

  /**
   * create a gamble request in case of unstaking or claim with gambling
   */
  function _requestGamble(address owner, uint action) internal whenGambleRequested {

    require(stakes[owner].length > 0, 'Stake first');
    require(action == GAMBLE_CLAIM || action == GAMBLE_UNSTAKE || action == GAMBLE_UNSTAKE_GREDDY, 'Invalid action');
    if (action != GAMBLE_CLAIM) {
      _collectStakeProfit(owner, true);
    }
    gambleRequests[owner] = Gamble({
      action: action,
      blockNumber: block.number
    });
  }

  /**
   * return gamble request status
   */
  function _gambleRequestState(address requestor) internal view returns (uint blockNumber, uint action, uint state, uint open, uint timeout) {
    Gamble memory req = gambleRequests[requestor];
    blockNumber = req.blockNumber;
    action = req.action;
    state = boxState(req.blockNumber);
    open = openCountdown(req.blockNumber);
    timeout = timeoutCountdown(req.blockNumber);
  }

  
  /**
   * claim all profits and take back staked tokens in case of unstaking
   * 20% chance to lose one of the hounds and adopted by other hunter
   * if players chooses to gamble, 50% chance to burn all the profits
   */
  function _unstake(address owner, Prey prey, HunterHound hh) internal {
    uint requestBlockNumber = gambleRequests[owner].blockNumber;
    require(requestBlockNumber > 0, "No unstake request found");
    uint action = gambleRequests[owner].action;
    require(action == GAMBLE_UNSTAKE || action == GAMBLE_UNSTAKE_GREDDY, "Claim first");

    uint256 totalProfit = _claimProfit(owner, true);

    uint random = openBox(requestBlockNumber);
    uint percent = percentNumber(random);

    address houndRecipient;
    if (percent <= 20) {
      //draw a player who has a hunter in case of losing
      houndRecipient= selectLuckyRecipient(owner, percent);
      if (houndRecipient != address(0)) {
        houndsCaptured = houndsCaptured + 1;
      }
    }

    uint receiveProfit = totalProfit;
    if (action == GAMBLE_UNSTAKE_GREDDY) {
      // 50/50 chance to lose all or take all
      if (percent > 0) {
        random = randomNumber(requestBlockNumber, random);
        percent = percentNumber(random);
        if (percent <= 50) {
          receiveProfit = 0;
        }
      } else {
          receiveProfit = 0;
      }
    } else {
      receiveProfit = (receiveProfit * 80) / 100;
    }


    delete gambleRequests[owner];

    uint totalHunter = 0;
    uint totalHound = 0;
    uint256 capturedTokenId;
    (totalHunter, totalHound, capturedTokenId) = _cleanOwner(percent, owner, hh, houndRecipient);
    
    hunterStaked = hunterStaked - totalHunter;
    houndStaked = houndStaked - totalHound;
    delete stakes[owner];

    if (receiveProfit > 0) {
      prey.mintByForest(owner, receiveProfit);
    }

    if (totalProfit - receiveProfit > 0) {
      totalBurned = totalBurned + (totalProfit - receiveProfit);
    }
    emit UnstakeEvent(owner, houndRecipient, capturedTokenId, receiveProfit, totalProfit);
  }

  /**
   * delete all data on staking, if `houndRecipient` exists, use `percent` to generate a random number and choose a hound to transfer
   */
  function _cleanOwner(uint percent, address owner, HunterHound hh, address houndRecipient) private returns(uint totalHunter, uint totalHound, uint256 capturedTokenId) {
    uint randomRow = percent % stakes[owner].length;
    for (uint256 i = 0; i < stakes[owner].length; i++) {
      Stake memory stake = stakes[owner][i];
      totalHound = totalHound + stake.tokenIds.length;
      if (stake.hunter) {
        totalHunter = totalHunter + 1;
        totalHound = totalHound - 1;
        uint256 hunterTokenId = stake.tokenIds[stake.tokenIds.length-1];
        uint alphaHunterLength = hunterAlphaMap[stake.alpha].length;
        if (alphaHunterLength > 1 && hunterTokenIndices[hunterTokenId] < (alphaHunterLength-1)) {
          uint lastHunterTokenId = hunterAlphaMap[stake.alpha][alphaHunterLength - 1];
          hunterTokenIndices[lastHunterTokenId] = hunterTokenIndices[hunterTokenId];
          hunterAlphaMap[stake.alpha][hunterTokenIndices[hunterTokenId]] = lastHunterTokenId;
        }
        
        hunterAlphaMap[stake.alpha].pop();
        delete hunterTokenIndices[hunterTokenId];
      }
      
      for (uint256 j = 0; j < stake.tokenIds.length; j++) {
        uint256 tokenId = stake.tokenIds[j];
        
        delete tokenOwners[tokenId];
        
        // randomly select 1 hound
        if (i == randomRow && houndRecipient != address(0) && (stake.tokenIds.length == 1 || j == (percent % (stake.tokenIds.length-1)))) {
          hh.transferByController(address(this), houndRecipient, tokenId);
          capturedTokenId = tokenId;
        } else {
          hh.transferByController(address(this), owner, tokenId);
        }
      }
    }
  }

  /**
   * of all hunters staked, choose one to adopt the hound, hunter with higher alpha score takes precedence.
   * alpha 8: 50%
   * alpha 7: 30%
   * alpha 6: 15%
   * alpha 5: 5%
   */
  function selectLuckyRecipient(address owner, uint seed) private view returns (address) {
    uint random = simpleRandom(seed);
    uint percent = percentNumber(random);
    uint alpha;
    if (percent <= 5) {
      alpha = 5;
    } else if (percent <= 20) {
      alpha = 6;
    } else if (percent <= 50) {
      alpha = 7;
    } else {
      alpha = 8;
    }
    uint alphaCount = 4;
    uint startAlpha = alpha;
    bool directionUp = true;
    while(alphaCount > 0) {
      alphaCount --;
      uint hunterCount = hunterAlphaMap[alpha].length;
      if (hunterCount != 0) {
        
        uint index = random % hunterCount;
        uint count = 0;
        while(count < hunterCount) {
          if (index >= hunterCount) {
            index = 0;
          }
          address hunterOwner = tokenOwners[hunterAlphaMap[alpha][index]];
          if (owner != hunterOwner) {
            return hunterOwner;
          }
          index ++;
          count ++;
        }
      }
      if (alpha >= 8) {
        directionUp = false;
        alpha = startAlpha;
      } 
      if (directionUp) {
        alpha ++;
      } else {
        alpha --;
      }
    }

    return address(0);
  }

  /**
   * calculate the claimable profits of the stake 
   */
  function _caculateProfit(Stake memory stake) internal view returns (uint) {
    uint profitPerStake = 0;
    if (stake.hunter) {
      profitPerStake = ((stake.hounds * PROFIT_PER_SINGLE_HOUND) * (stake.alpha + 10)) / 10;
    } else {
      profitPerStake = stake.hounds * PROFIT_PER_SINGLE_HOUND;
    }

    return (block.timestamp - stake.timestamp) * profitPerStake / 1 days;
  }

  /**
   * take back all staked tokens in case of rescue mode
   */
  function _rescue(address owner, HunterHound hh) internal {
    delete gambleRequests[owner];
    uint totalHound = 0;
    uint totalHunter = 0;
    (totalHunter, totalHound, ) = _cleanOwner(0, owner, hh, address(0));
    delete stakes[owner];
    houndStaked = houndStaked - totalHound;
    hunterStaked = hunterStaked - totalHunter;
  }
}