pragma solidity ^0.8.10;

import "OwnableUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "IERC721ReceiverUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "EnumerableSetUpgradeable.sol";
import "Strings.sol";

import "IChubbyKaijuDAOStakingV1.sol";
import "IChubbyKaijuDAOCrunch.sol";
import "IChubbyKaijuDAOGEN1.sol";

/***************************************************************************************************
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------://:-----------------------------------------------------
------------------------------:/osys+-----smddddo:--------------------------------------------------
-----------------------------ommhysymm+--oMy/:/sNm/-------------------------------------------------
----------------------------oMy/::::/hNy:Nm:::::/mN/------------------------------------------------
----------------------------dM/:::::::oNNMs:::::/+Nm++++/::-----------------------------------------
----------------------------dM/::::::::+NM+::+shdmmmddddmNmdy+:-------------------------------------
----------------------------yM+:::::::::hMoymNdyo+////////+symNho-----------------------------------
----------------------------+My:::::::::dMNho/////////////////+yNNs---------------------------------
-----------------------:+sso+Mm:::::::yNmy+//////////////////////sNNo-------------------------------
----------------------yNdyyhdMMo::::omNs+/////////////////////////+hMh------------------------------
---------------------/Md:::::+Nm::/hMh+/////////////////////////////sNd:----------------------------
---------------------+My::::::yMs/dNs+///////////////////////////////oNd----------------------------
---------------------:Md:::::::dNmNo/////////+++////////////////shmdhosMy---------------------------
----------------------dM+::::::/NMs////////+hmdmdo/////////////yNy-:dNodM/--------------------------
----------------------:Nm/:::::sMy////////+mN:`-Nm+///////////+Mh   :MhsMy--------------------------
-----------------------sMm+::::NN+////////sMs   sMs///////////oMs   -Md+Md--------------------------
----------------------sNdmNo::sMm+////////sMo   -Mh///////++oosMm-..sMs/Mm:-------------------------
----------------------mM:/ym+sNmy+////////+Md```+My///+oydmmmmmddmmmNMhshNm+------------------------
----------------------oMy:::hMh+///////////yMddmNN++sdmmdys+///////shhhNmhmM/-----------------------
-----------------------yMh:yMy////////////+mNyo+++smNhoodhh+///////shy/+smMMh-----/+osoo+:----------
------------------------oNmMN//////////////++////hMy+///+Mh////////dM+///+hMy---odMmdhhdmNNdo-------
-------------------------:hMd/////////////////sd+++/////+dy////////os/////+NN-/m++Mh+/oo+/oymNs-----
---------------------------Mm///////////++///+NMy/////////////////////////+NN-+m-hMsoo/ooo++ohMy----
---------------------------yMy//////////////smNdMms+/////////+ossyso+////odMosdddNhoooooooosyyNM:---
----------------------------hMy+///////+s+//yy++NMmNdhyssyhdNNNmmmmNNdhhmmh+yhyMmddhhhhhymNdddmNd+--
------------------------:::--sNms+//////+///++//sMd+oyhhhyssdMmhhhhdMmhMd/odMNMNmdmhhddhMNs+//+oyNh:
----------------------+dddddh+oMNs//////////++///sNd+:::::::/dMdhhdNNooMy/MNyyyhhhhdddmMNmmmmdo//sMh
---------------------oNh+//+hMNdo/////////////////omNy+::::::+MNhmMmo/hM+-hMmddhhds/:/NNo++oos+///dM
--------------------:Nm::::+mNs+///////////////////+sdmdyo+++oMMNmy++yMMs-/MmhhdddmmdhMNhhyso+////hM
----------------::::oMs:::sNd+////////////////////////oshdmmmmdyo++odNhyNd/mmddhyyyyhmMdyyhmms////dM
--------------/hmmmdmMo::hMh+////++osssso++///////////////++++++oydNdo//omN+/+oyhdmNNNMy////+////+NN
-------------/Nm+::/sMh:hMy///+sdmNmdddmNmds+////////////oddddmNmhyo/////+dNo-----/MmodNhs+//////sMs
-------------dM/:::::ssdMs//+yNNho+o++oooshNNy+//////////+ssso++//////////+dM+---+mNo//shmm+////oNm-
-------------Mm:::::::hMy//+dMh/+ooo/oo/+ooohMd+////////+++////////////////+mN/yNNy+//////////+yNm:-
-------------NN::::::sMh///dMyo+oooooooooooooyMd//+shmmmdddmmdho////////////oMMms//////////+dNNh+---
-------------hM+::::+Mm+//+MmooooooooooooosyhhmMmhNhs/::---::/sdNh+////+yo//+MN+////////////dM+-----
-------------/Mh::::dMo///+MNyyyyyyhhhhhddhdmddmMd::-----------:/hNy+//+Mm//yMs////////////oMd------
--------------hM+::oMh////+MNhdhhdddmddmmmNNddddMN:---------------+mmo//dMo/+o+////////////dM+------
------------:ohMm::mM+//+hNMNmmNNmdddhhyhdhhhddhNM/----------------:dNo/sMy///////////////oMd-------
-----------+NmsyMs+Md///hMymMmMNNmooo//hmddddddmMh------------------:mm++Mm///////////////dM/-------
-----------dM/::hhyMs///dMoyMNs+hMNddmNNdddhssshMy-------------------+My/mM+/////////////sMh--------
-----------dM/::::mM+///sMhyMh/oNmo//oMNmmmmmmmmy:--------------------mN/hMs////////////+NN:--------
-----------sMs::::NN////+dMNM+/mMo///+NNy+/oNN/:----------------------sMoyMy///////////+dN+---------
------------mN/::/Mm/////+yMN+oMd///+mNo///+NN------------------------+MsoMh//////////omN+----------
------------/Nd/:/Md/////+hMNddMm+/+dMs///+hMs------------------------/My+Md////////+yNm/-----------
-------------+Md//Mm////+mNsosyyNNhmMMs++odMs-------------------------:Mh+MNhso++oydNdo-------------
--------------+Nm/NN///+mMo/////+ossodNNNmy/--------------------------:Mh/MNsdmmmdyo:---------------
***************************************************************************************************/

contract ChubbyKaijuDAOStakingV1 is IChubbyKaijuDAOStakingV1, OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  using Strings for uint128;

  uint32 public totalPowerStaked; // trait 0
  uint32 public totalMoneyStaked; // trait 1
  uint32 public totalMusicStaked; // trait 2



  uint48 public lastClaimTimestamp;

  uint48 public constant MINIMUM_TO_EXIT = 1 days;

  uint128 public constant MAXIMUM_CRUNCH = 18000000 ether;

  uint128 public totalCrunchEarned;

  uint128 public constant CRUNCH_EARNING_RATE = 115740; //74074074; // 1 crunch per day;
  uint128 public constant TIME_BASE_RATE = 100000000;

  struct TimeStake { uint16 tokenId; uint48 time; address owner; uint16 trait; uint16 reward_type;}

  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);

  IChubbyKaijuDAOGEN1 private chubbykaijuGen1;
  IChubbyKaijuDAOCrunch private chubbykaijuDAOCrunch;


  TimeStake[] public gen1StakeByToken; 
  mapping(uint16 => uint16) public gen1Hierarchy; 
  mapping(address => EnumerableSetUpgradeable.UintSet) private _gen1StakedTokens;


  address private common_address;
  address private uncommon_address;
  address private rare_address;
  address private epic_address;
  address private sos_address;
  address private one_address;

  

  struct rewardTypeStaked{
    uint32  common_gen1; // reward_type: 0 -> 1*1*(1+Time weight)
    uint32  uncommon_gen1; // reward_type: 1 -> 1*1*(1+Time weight)
    uint32  rare_gen1; // reward_type: 2 -> 2*1*(1+Time weight)
    uint32  epic_gen1; // reward_type: 3 -> -> 3*1*(1+Time weight)
    uint32  sos_gen1; // reward_type: 4 -> 5*1*(1+Time weight)
    uint32  one_gen1; // reward_type: 5 -> 15*1*(1+Time weight)

  }

  rewardTypeStaked private rewardtypeStaked;

  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    _pause();
  }

  function setSigners(address[] calldata signers) public onlyOwner{
    common_address = signers[0];
    uncommon_address = signers[1];
    rare_address = signers[2];
    epic_address = signers[3];
    sos_address = signers[4];
    one_address = signers[5];
  }


  function stakeTokens(address account, uint16[] calldata tokenIds, bytes[] memory signatures) external whenNotPaused nonReentrant _updateEarnings {
    require((account == msg.sender), "only owners approved");
    
    for (uint16 i = 0; i < tokenIds.length; i++) {
      require(chubbykaijuGen1.ownerOf(tokenIds[i]) == msg.sender, "only owners approved");
      uint16 trait = tokenIds[i]>9913? 2:chubbykaijuGen1.traits(tokenIds[i]); // hard-code music country for the mislead traits variable (from 9914 to 9999)
      _stakeGEN1(account, tokenIds[i], trait, signatures[i]);
      chubbykaijuGen1.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  
  }


  function _stakeGEN1(address account, uint16 tokenId, uint16 trait, bytes memory signature) internal {
    if(trait == 0){
      totalPowerStaked += 1;
    }else if(trait == 1){
      totalMoneyStaked += 1;
    }else if(trait == 2){
      totalMusicStaked += 1;
    }
    address rarity = rarityCheck(tokenId, signature);
    uint16 reward_type = 0;

    if(rarity == common_address){
      reward_type = 0;
      rewardtypeStaked.common_gen1 +=1;
    }else if(rarity == uncommon_address){
      reward_type = 1;
      rewardtypeStaked.uncommon_gen1 +=1;
    }else if(rarity == rare_address){
      reward_type = 2;
      rewardtypeStaked.rare_gen1 +=1;
    }else if (rarity == epic_address){
      reward_type = 3;
      rewardtypeStaked.epic_gen1 +=1;
    }else if(rarity == sos_address){
      reward_type = 4;
      rewardtypeStaked.sos_gen1 +=1;
    }else if(rarity == one_address){
      reward_type = 5;
      rewardtypeStaked.one_gen1 +=1;
    }

    gen1Hierarchy[tokenId] = uint16(gen1StakeByToken.length);
    gen1StakeByToken.push(TimeStake({
        owner: account,
        tokenId: tokenId,
        time: uint48(block.timestamp),
        trait: trait,
        reward_type: reward_type
    }));
    _gen1StakedTokens[account].add(tokenId); 
    

    emit TokenStaked("CHUBBYKAIJUGEN1", tokenId, account);
  }



  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      reward += _claimGEN1(tokenIds[i], unstake, time);
    }
    if (reward != 0) {
      chubbykaijuDAOCrunch.mint(msg.sender, reward);
    }
  }


  function _claimGEN1(uint16 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    TimeStake memory stake = gen1StakeByToken[gen1Hierarchy[tokenId]];
    uint16 trait = stake.trait;
    uint16 reward_type = stake.reward_type;
    require(stake.owner == msg.sender, "only owners can unstake");
    require(!(unstake && block.timestamp - stake.time < MINIMUM_TO_EXIT), "need 1 day to unstake");

    reward = _calculateGEN1Rewards(tokenId);

    if (unstake) {
      TimeStake memory lastStake = gen1StakeByToken[gen1StakeByToken.length - 1];
      gen1StakeByToken[gen1Hierarchy[tokenId]] = lastStake; 
      gen1Hierarchy[lastStake.tokenId] = gen1Hierarchy[tokenId];
      gen1StakeByToken.pop(); 
      delete gen1Hierarchy[tokenId]; 

      if(trait == 0){
        totalPowerStaked -= 1;
      }else if(trait == 1){
        totalMoneyStaked -= 1;
      }else if(trait == 2){
        totalMusicStaked -= 1;
      }
      if(reward_type == 0){
        rewardtypeStaked.common_gen1 -=1;
      }else if(reward_type == 1){
        rewardtypeStaked.uncommon_gen1 -= 1;
      }else if(reward_type == 2){
        rewardtypeStaked.rare_gen1 -= 1;
      }else if(reward_type == 3){
        rewardtypeStaked.epic_gen1 -= 1;
      }else if(reward_type == 4){
        rewardtypeStaked.sos_gen1 -= 1;
      }else if(reward_type == 5){
        rewardtypeStaked.one_gen1 -= 1;
      }
      _gen1StakedTokens[stake.owner].remove(tokenId); 
      chubbykaijuGen1.transferFrom(address(this), msg.sender, tokenId);

      emit TokenUnstaked("CHUBBYKAIJUGEN1", tokenId, stake.owner, reward);
    } 
    else {
      gen1StakeByToken[gen1Hierarchy[tokenId]] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time,
        trait: trait,
        reward_type: reward_type
      });
    }
    
  }


  function _calculateGEN1Rewards(uint16  tokenId) internal view returns (uint128 reward) {
    require(tx.origin == msg.sender, "eos only");
    TimeStake memory stake = gen1StakeByToken[gen1Hierarchy[tokenId]];

    uint48 time = uint48(block.timestamp);
    uint16 reward_type = stake.reward_type;
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake.time > 3600*24*120? 6*TIME_BASE_RATE: 60*(time-stake.time);
      if(reward_type == 0){
        reward = 1*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 1){
        reward = 1*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 2){
        reward = 2*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 3){
        reward = 3*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 4){
        reward = 5*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 5){
        reward = 15*1*(time-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }
    } 
    else if (stake.time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake.time > 3600*24*120? 6*TIME_BASE_RATE: 60*(lastClaimTimestamp-stake.time);
      if(reward_type == 0){
        reward = 1*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 1){
        reward = 1*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 2){
        reward = 2*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 3){
        reward = 3*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 4){
        reward = 5*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 5){
        reward = 15*1*(lastClaimTimestamp-stake.time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }
    }
  }
  function calculateGEN1Rewards(uint16  tokenId) external view returns (uint128) {
    return _calculateGEN1Rewards(tokenId);
  }

  modifier _updateEarnings() {
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint48 time = uint48(block.timestamp);
      uint128 temp = (1*1*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.common_gen1);
      uint128 temp2 = 100000000+60*(time - lastClaimTimestamp);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (1*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.uncommon_gen1);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (2*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.rare_gen1);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (3*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.epic_gen1);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (5*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.sos_gen1);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (15*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.one_gen1);
      temp *= temp2;
      totalCrunchEarned += temp;
      
      lastClaimTimestamp = time;
    }
    _;
  }

  function GEN1depositsOf(address account) external view returns (uint16[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _gen1StakedTokens[account];
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

  function setGEN1Contract(address _address) external onlyOwner {
    chubbykaijuGen1 = IChubbyKaijuDAOGEN1(_address);
  }

  function setCrunchContract(address _address) external onlyOwner {
    chubbykaijuDAOCrunch = IChubbyKaijuDAOCrunch(_address);
  }

  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
  }

  function rarityCheck(uint16 tokenId, bytes memory signature) public view returns (address) {
      bytes32 messageHash = keccak256(Strings.toString(tokenId));
      bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

      return recoverSigner(ethSignedMessageHash, signature);
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
      return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
      require(sig.length == 65, "sig invalid");

      assembly {
      /*
      First 32 bytes stores the length of the signature

      add(sig, 32) = pointer of sig + 32
      effectively, skips first 32 bytes of signature

      mload(p) loads next 32 bytes starting at the memory address p into memory
      */

      // first 32 bytes, after the length prefix
          r := mload(add(sig, 32))
      // second 32 bytes
          s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
          v := byte(0, mload(add(sig, 96)))
      }

      // implicitly return (r, s, v)
  }

  

  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {    
    require(from == address(0x0), "only allow directly from mint");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}