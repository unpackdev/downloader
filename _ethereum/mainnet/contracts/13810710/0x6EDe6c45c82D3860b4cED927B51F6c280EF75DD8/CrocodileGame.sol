/*
 ██████╗██████╗  ██████╗  ██████╗ ██████╗ ██████╗ ██╗██╗     ███████╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔═══██╗██╔══██╗██║██║     ██╔════╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
██║     ██████╔╝██║   ██║██║     ██║   ██║██║  ██║██║██║     █████╗      ██║  ███╗███████║██╔████╔██║█████╗  
██║     ██╔══██╗██║   ██║██║     ██║   ██║██║  ██║██║██║     ██╔══╝      ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
╚██████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝██████╔╝██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
 ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "OwnableUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "EnumerableSetUpgradeable.sol";

import "ICrocodileGame.sol";
import "ICrocodileGamePiranha.sol";
import "ICrocodileGameNFT.sol";
import "ICrocodileGameWARDER.sol";

contract CrocodileGame is ICrocodileGame, OwnableUpgradeable, IERC721ReceiverUpgradeable,
                    PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  /**
   * First of all, thanks for checking out our contracts.
   * We implemented the following concepts:
   * (1) Semi-Onchain Concept (predefined traits distribution then injects the randomness when minting),
   * (2) Dilemma game implementation.
   * (3) O(1) space complexity implementation for efficiency.

   * Feel free to contract us if there are any concerns or reports.
   * We used the fox.game code as the baseline.
   
   * We hope our concept & implementation shed a light on NFT game society.
   **/

  uint32 public totalCrocodilesStaked;

  uint32 public totalCrocodilebirdsStaked;

  uint16 public totalStakedCooperate;
  uint16 public totalStakedBetray;

  uint48 public lastClaimTimestamp;

  uint48 public constant MINIMUM_TO_EXIT = 1 days;

  uint128 public constant MAXIMUM_GLOBAL_PIRANHA = 900000000 ether;

  uint128 public totalPiranhaEarned;

  uint128 public constant CROCODILE_EARNING_RATE = 115740740740740740; // 10000 ether / 1 days;
  uint128 public constant CROCODILEBIRD_EARNING_RATE = 115740740740740740; // 10000 ether / 1 days;

  struct TimeStake { uint16 tokenId; uint48 time; address owner; }
  struct KarmaStake { uint16 tokenId; address owner; uint8 karmaP; uint8 karmaM; }

  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);

  ICrocodileGameNFT private crocodileNFT;
  ICrocodileGamePiranha private crocodilePiranha;
  ICrocodileGameWARDER private crocodileWARDER;
  bool isWARDER = false;

  KarmaStake[] public karmaStake;
  mapping(uint16 => uint16[]) public karmaHierarchy;
  uint8 karmaStakeLength;

  TimeStake[] public crocodileStakeByToken; // crocodile storage
  mapping(uint16 => uint16) public crocodileHierarchy; // crocodile location within group

  TimeStake[] public crocodilebirdStakeByToken; // crocodile bird storage
  mapping(uint16 => uint16) public crocodilebirdHierarchy; // bird location within group

  mapping(address => EnumerableSetUpgradeable.UintSet) private _stakedTokens;


  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    //_pause();
  }


  function stakeTokens(address account, uint16[] calldata tokenIds, uint8[] calldata dilemmas) external whenNotPaused nonReentrant _updateEarnings {
    require((account == msg.sender && tx.origin == msg.sender) || msg.sender == address(crocodileNFT), "not approved");
    
    for (uint16 i = 0; i < tokenIds.length; i++) {
      if (msg.sender != address(crocodileNFT)) { 
        require(crocodileNFT.ownerOf(tokenIds[i]) == msg.sender, "only token owners can stake");
      }
      require((crocodileNFT.getTraits(tokenIds[i]).kind == 0) || (crocodileNFT.getTraits(tokenIds[i]).kind == 1), "traits overlaps");
      
      if (crocodileNFT.getTraits(tokenIds[i]).kind==0)
      { // CROCODILE
        _addCrocodileToSwamp(account, tokenIds[i], dilemmas[i]);
      } 
      else { // CROCODILEBIRD
        _addCrocodilebirdToNest(account, tokenIds[i], dilemmas[i]);
      }

      if (msg.sender != address(crocodileNFT)) {
        require(crocodileNFT.ownerOf(tokenIds[i]) == msg.sender, "only token owners can stake");
        crocodileNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
      }
    }
  }


  function _addCrocodileToSwamp(address account, uint16 tokenId, uint8 dilemma) internal {

    if(dilemma==1){ // for COOPERATE
      if (crocodileNFT.getTraits(tokenId).karmaM>0){
        crocodileNFT.setKarmaM(tokenId, crocodileNFT.getTraits(tokenId).karmaM-1);
      }
      else{
        karmaHierarchy[tokenId].push(karmaStakeLength);
        karmaStakeLength++;
        karmaStake.push(KarmaStake({
          tokenId: tokenId,
          owner: account,
          karmaP: crocodileNFT.getTraits(tokenId).karmaP,
          karmaM: 0
        }));

        crocodileNFT.setKarmaP(tokenId, crocodileNFT.getTraits(tokenId).karmaP+1);
      }
    } 
    else{ // for BETRAY
      if(crocodileNFT.getTraits(tokenId).karmaP>0){
        KarmaStake memory KlastStake = karmaStake[karmaStakeLength-1];
        karmaStake[karmaHierarchy[tokenId][crocodileNFT.getTraits(tokenId).karmaP-1]] = KlastStake;
        karmaHierarchy[KlastStake.tokenId][KlastStake.karmaP] = karmaHierarchy[tokenId][crocodileNFT.getTraits(tokenId).karmaP-1];
        karmaStake.pop();
        karmaStakeLength--;
        karmaHierarchy[tokenId].pop();
        crocodileNFT.setKarmaP(tokenId, crocodileNFT.getTraits(tokenId).karmaP-1);
      }
      else{
        crocodileNFT.setKarmaM(tokenId, crocodileNFT.getTraits(tokenId).karmaM+1);
      }
    }
    crocodileHierarchy[tokenId] = uint16(crocodileStakeByToken.length);
    crocodileStakeByToken.push(TimeStake({
        owner: account,
        tokenId: tokenId,
        time: uint48(block.timestamp)
    }));
    
    totalCrocodilesStaked += 1;
    _stakedTokens[account].add(tokenId); 

    if (dilemma==1)
    {totalStakedCooperate += 1;}
    else if (dilemma==2)
    {totalStakedBetray += 1;}

    emit TokenStaked("CROCODILE", tokenId, account);
  }


  function _addCrocodilebirdToNest(address account, uint16 tokenId, uint8 dilemma) internal {

    if(dilemma==1){ // for Cooperating
      if(crocodileNFT.getTraits(tokenId).karmaM>0){
        crocodileNFT.setKarmaM(tokenId, crocodileNFT.getTraits(tokenId).karmaM-1);
      }
      else{
        karmaHierarchy[tokenId].push(karmaStakeLength);
        karmaStakeLength++;
        karmaStake.push(KarmaStake({
          tokenId: tokenId,
          owner: account,
          karmaP: crocodileNFT.getTraits(tokenId).karmaP,
          karmaM: 0
        }));
        crocodileNFT.setKarmaP(tokenId, crocodileNFT.getTraits(tokenId).karmaP+1);
      }
    }
    else{ // for Betraying
      if(crocodileNFT.getTraits(tokenId).karmaP>0){
        KarmaStake memory KlastStake = karmaStake[karmaStakeLength-1];
        karmaStake[karmaHierarchy[tokenId][crocodileNFT.getTraits(tokenId).karmaP-1]] = KlastStake;
        karmaHierarchy[KlastStake.tokenId][KlastStake.karmaP] = karmaHierarchy[tokenId][crocodileNFT.getTraits(tokenId).karmaP-1];
        karmaStake.pop();
        karmaStakeLength--;
        karmaHierarchy[tokenId].pop();
        crocodileNFT.setKarmaP(tokenId, crocodileNFT.getTraits(tokenId).karmaP-1);
      }
      else{
        crocodileNFT.setKarmaM(tokenId, crocodileNFT.getTraits(tokenId).karmaM+1);
      }
    }

    crocodilebirdHierarchy[tokenId] = uint16(crocodilebirdStakeByToken.length);
    crocodilebirdStakeByToken.push(TimeStake({
        owner: account,
        tokenId: tokenId,
        time: uint48(block.timestamp)
    }));

    totalCrocodilebirdsStaked += 1;
    _stakedTokens[account].add(tokenId);

    if (dilemma==1)
    {totalStakedCooperate += 1;}
    else if (dilemma==2)
    {totalStakedBetray += 1;}

    emit TokenStaked("CROCODILEBIRD", tokenId, account);
  }
  
  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake, uint256 seed) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      if (crocodileNFT.getTraits(tokenIds[i]).kind==0) {
        reward += _claimCrocodilesFromSwamp(tokenIds[i], unstake, time, seed);
      } else { 
        reward += _claimCrocodilebirdsFromNest(tokenIds[i], unstake, time, seed);
      }
    }
    if (reward != 0) {
      if(!isWARDER){
        crocodilePiranha.mint(msg.sender, reward);
      }else{
        if(crocodileWARDER.isOwner(msg.sender)){
          crocodilePiranha.mint(msg.sender, reward*2);
        }else{
          crocodilePiranha.mint(msg.sender, reward);
        }
      }
    }
  }


  function _claimCrocodilesFromSwamp(uint16 tokenId, bool unstake, uint48 time, uint256 seed) internal returns (uint128 reward) {
    TimeStake memory stake = crocodileStakeByToken[crocodileHierarchy[tokenId]];
    require(stake.owner == msg.sender, "only token owners can unstake");
    require(!(unstake && block.timestamp - stake.time < MINIMUM_TO_EXIT), "crocodiles need 1 days of piranha");

    if (totalPiranhaEarned < MAXIMUM_GLOBAL_PIRANHA) {
      reward = (time - stake.time) * CROCODILE_EARNING_RATE;
    } 
    else if (stake.time <= lastClaimTimestamp) {
      reward = (lastClaimTimestamp - stake.time) * CROCODILE_EARNING_RATE;
    }
    bool burn = false;
    if (unstake) {
      
      uint8 dilemma = crocodileNFT.getTraits(tokenId).dilemma;
      uint16 randToken = _randomCrocodilebirdToken(seed);
      if(dilemma==1){ // for Cooperate
        totalStakedCooperate -= 1;
        crocodileNFT.setDilemma(tokenId, 0);
        if(randToken>0){
          if(crocodileNFT.getTraits(randToken).dilemma==2){
            reward = 0;
          }
        }
        
      }
      else if(dilemma==2){ // for Betray
        totalStakedBetray -= 1;
        crocodileNFT.setDilemma(tokenId, 0);
        if(randToken>0){
          if(crocodileNFT.getTraits(randToken).dilemma==1){
            reward *= 2;
          }
          else if(crocodileNFT.getTraits(randToken).dilemma==2){
            reward = 0;

            if(crocodileNFT.getTraits(tokenId).karmaM == 2){
              seed >>= 64;
              if( seed%1001 < 309){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 3){
              seed >>= 64;
              if( seed%1001 < 500){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 4){
              seed >>= 64;
              if( seed%1001 < 691){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 5){
              seed >>= 64;
              if( seed%1001 < 841){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 6){
              seed >>= 64;
              if( seed%1001 < 933){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 7){
              seed >>= 64;
              if( seed%1001 < 977){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 8){
              seed >>= 64;
              if( seed%1001 < 993){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 9){
              seed >>= 64;
              if( seed%1001 < 997){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM >= 10){ 
              burn = true;
            }
          }
          if(burn) {crocodileNFT.burn(tokenId);}
        }
      }
      TimeStake memory lastStake = crocodileStakeByToken[crocodileStakeByToken.length - 1];
      crocodileStakeByToken[crocodileHierarchy[tokenId]] = lastStake; 
      crocodileHierarchy[lastStake.tokenId] = crocodileHierarchy[tokenId];
      crocodileStakeByToken.pop(); 
      delete crocodileHierarchy[tokenId]; 

      totalCrocodilesStaked -= 1;
      _stakedTokens[stake.owner].remove(tokenId); 


      if(!burn) crocodileNFT.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } 
    else {
      reward = reward / 2;      
      crocodileStakeByToken[crocodileHierarchy[tokenId]] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }
    emit TokenUnstaked("CROCODILE", tokenId, stake.owner, reward);
  }


  function _claimCrocodilebirdsFromNest(uint16 tokenId, bool unstake, uint48 time, uint256 seed) internal returns (uint128 reward) {

    TimeStake memory stake = crocodilebirdStakeByToken[crocodileHierarchy[tokenId]];
    require(stake.owner == msg.sender, "only token owners can unstake");
    require(!(unstake && block.timestamp - stake.time < MINIMUM_TO_EXIT), "crocodile birds need 1 days of piranha");

    if (totalPiranhaEarned < MAXIMUM_GLOBAL_PIRANHA) {
      reward = (time - stake.time) * CROCODILEBIRD_EARNING_RATE;
    } 
    else if (stake.time <= lastClaimTimestamp) {
      reward = (lastClaimTimestamp - stake.time) * CROCODILEBIRD_EARNING_RATE;
    }
    bool burn = false;
    if (unstake) {
      uint8 dilemma = crocodileNFT.getTraits(tokenId).dilemma;
      uint16 randToken = _randomCrocodileToken(seed);
      if(dilemma==1){ // for COOPERATE
        totalStakedCooperate -= 1;
        crocodileNFT.setDilemma(tokenId, 0);
        if(randToken>0){
          if(crocodileNFT.getTraits(randToken).dilemma==2){
            reward = 0;
          }
        }
        
      }
      else if(dilemma==2){ // for BETRAY
        totalStakedBetray -= 1;
        crocodileNFT.setDilemma(tokenId, 0);
        if(randToken>0){
          if(crocodileNFT.getTraits(randToken).dilemma==1){
            reward *= 2;
          }
          else if(crocodileNFT.getTraits(randToken).dilemma==2){
            reward = 0;

          /* karma ++ */
            if(crocodileNFT.getTraits(tokenId).karmaM == 2){
              seed >>= 64;
              if( seed%1001 < 309){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 3){
              seed >>= 64;
              if( seed%1001 < 500){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 4){
              seed >>= 64;
              if( seed%1001 < 691){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 5){
              seed >>= 64;
              if( seed%1001 < 841){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 6){
              seed >>= 64;
              if( seed%1001 < 933){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 7){
              seed >>= 64;
              if( seed%1001 < 977){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 8){
              seed >>= 64;
              if( seed%1001 < 993){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM == 9){
              seed >>= 64;
              if( seed%1001 < 997){
                burn=true;
              } 
            }else if(crocodileNFT.getTraits(tokenId).karmaM >= 10){ 
              burn = true;
            }
          }
          if(burn) {crocodileNFT.burn(tokenId);}
        }
      }
      TimeStake memory lastStake = crocodilebirdStakeByToken[crocodilebirdStakeByToken.length - 1];
      crocodilebirdStakeByToken[crocodilebirdHierarchy[tokenId]] = lastStake; 
      crocodilebirdHierarchy[lastStake.tokenId] = crocodilebirdHierarchy[tokenId];
      crocodilebirdStakeByToken.pop();
      delete crocodilebirdHierarchy[tokenId]; 

      totalCrocodilebirdsStaked -= 1;
      _stakedTokens[stake.owner].remove(tokenId);


      if(!burn) crocodileNFT.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      reward = reward / 2;
      crocodilebirdStakeByToken[crocodilebirdHierarchy[tokenId]] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit TokenUnstaked("CROCODILEBIRD", tokenId, stake.owner, reward);
  }


  modifier _updateEarnings() {
    if (totalPiranhaEarned < MAXIMUM_GLOBAL_PIRANHA) {
      uint48 time = uint48(block.timestamp);
      uint48 elapsed = time - lastClaimTimestamp;
      totalPiranhaEarned +=
        (elapsed * totalCrocodilesStaked * CROCODILE_EARNING_RATE) +
        (elapsed * totalCrocodilebirdsStaked * CROCODILEBIRD_EARNING_RATE);
      lastClaimTimestamp = time;
    }
    _;
  }

  function randomKarmaOwner(uint256 seed) external view returns (address) {
    if (karmaStakeLength == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    seed >>= 32;
    return karmaStake[seed % karmaStakeLength].owner;
  }

  function _randomCrocodileToken(uint256 seed) internal view returns (uint16) {
    if (totalCrocodilesStaked == 0) {
      return 0; 
    }
    seed >>= 32;
    return crocodileStakeByToken[seed % crocodileStakeByToken.length].tokenId;
  }

  function _randomCrocodilebirdToken(uint256 seed) internal view returns (uint16) {
    if (totalCrocodilebirdsStaked == 0) {
      return 0; 
    }
    seed >>= 32;
    return crocodilebirdStakeByToken[seed % crocodilebirdStakeByToken.length].tokenId;
  }

  function depositsOf(address account) external view returns (uint16[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _stakedTokens[account];
    uint16[] memory tokenIds = new uint16[] (depositSet.length());

    for (uint16 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint16(depositSet.at(i));
    }

    return tokenIds;
  }

  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function setNFTContract(address _address) external onlyOwner {
    crocodileNFT = ICrocodileGameNFT(_address);
  }


  function setPiranhaContract(address _address) external onlyOwner {
    crocodilePiranha = ICrocodileGamePiranha(_address);
  }

  function setWARDERContract(address _address) external onlyOwner {
    crocodileWARDER = ICrocodileGameWARDER(_address);
    isWARDER = true;
  }

  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {    
    require(from == address(0x0), "only allow directly from mint");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}