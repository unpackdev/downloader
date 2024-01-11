// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./IERC721.sol";

import "./MekaApesERC721.sol";
import "./OogearERC20.sol";
import "./IDMT_ERC20.sol";

enum OogaType { ROBOOOGA, MEKAAPE }

struct OogaAttributes {
    OogaType oogaType;
    uint8 level;

    bool staked;
    address stakedOwner;

    uint256 lastClaimTimestamp;
    uint256 savedReward;

    uint256 lastRewardPerPoint;
    uint256 stakedMegaIndex;
}

struct Prices {
    uint256 mintPrice;
    uint256 mintStakePrice;
    uint256[] mintOGprice;
    uint256[] mintOGstakePrice;
    uint256 mintDMTstakePrice;
    uint256[] roboLevelupPrice;
    uint256 mekaMergePrice;
}

struct PricesGetter {
    uint256 mintPrice;
    uint256 mintStakePrice;
    uint256 mintOGprice;
    uint256 mintOGstakePrice;
    uint256 mintDMTstakePrice;
    uint256[] roboLevelupPrice;
    uint256 mekaMergePrice;
    uint256[] roboLevelupPriceOG;
}

struct RandomsGas {
    uint256 mintBase;
    uint256 mintPerToken;
    uint256 mintPerTokenStaked;
    uint256 unstakeBase;
    uint256 unstakePerToken;
    uint256 mergeBase;
}

struct InitParams {
    MekaApesERC721 erc721Contract_;
    OogearERC20 ogToken_;
    IDMT_ERC20 dmtToken_;
    IERC721 oogaVerse_;
    address mintSigWallet_;
    address randomProvider_;
    Prices prices_;
    RandomsGas randomsGas_;
    uint256[] mintOGpriceSteps_;
    uint256[] roboOogaRewardPerSec_;
    uint256[] roboOogaMinimalRewardToUnstake_;
    uint256[] roboOogaRewardAttackProbabilities_;
    uint256[] megaLevelProbabilities_;
    uint256[] mekaLevelSharePoints_;
    uint256[] megaTributePoints_;
    uint256 claimTax_;
    uint256 maxMintWithDMT_;
    uint256 mintSaleAmount_;
    uint256 maxTokenSupply_;
    uint256 maxOgSupply_;
    uint256 addedOgForRewardsAtEnd_;
    uint256 ethMintAttackChance_;
    uint256 dmtMintAttackChance_;
    uint256 ogMintAttackChance_;
    uint256 randomMekaProbability_;
    uint256 publicMintAllowance_;
    uint256 maxMintedRewardTokens_;
    address[] mintETHWithdrawers_;
    uint256[] mintETHWithdrawersPercents_;
}

struct MintSignature {
    uint256 mintAllowance;
    uint8 _v;
    bytes32 _r; 
    bytes32 _s;
}

struct LeaderboardRewardSignature {
    uint256 reward;
    uint8 _v;
    bytes32 _r;
    bytes32 _s;
}

enum RandomRequestType { MINT, UNSTAKE, MERGE }

struct RandomRequest {
    RandomRequestType requestType;
    address user;
    bool active;
}

struct ClaimRequest {
    uint256 totalMekaReward;
    uint256[] roboOogas;
    uint256[] roboOogasAmounts;
}

struct MintRequest {
    uint32 startFromId;
    uint8 amount;
    uint8 attackChance;
    bool toStake;
}

struct Crew {
    address owner;
    uint256[] oogas;
    uint256 lastClaimTimestamp;
    uint256 totalRewardPerSec;
    uint256 savedReward;
    uint256 oogaCount;
}

contract MekaApesGame_2 is OwnableUpgradeable {

    MekaApesERC721 public erc721Contract;
    OogearERC20 public ogToken;
    IDMT_ERC20 public dmtToken;
    IERC721 public oogaVerse;

    address public mintSigWallet;
    address public randomProvider;

    Prices public prices;
    RandomsGas public randomsGas;

    uint256[] public mintOGpriceSteps;
    uint256 public currentOgPriceStep;

    uint256[] public roboOogaRewardPerSec;
    uint256[] public roboOogaMinimalRewardToUnstake;
    uint256[] public roboOogaRewardAttackProbabilities;

    uint256 public claimTax;

    uint256 public nextTokenId;

    uint256 public tokensMintedWithDMT;
    uint256 public maxMintWithDMT;

    uint256 public ethMintAttackChance;
    uint256 public dmtMintAttackChance;
    uint256 public ogMintAttackChance;
    uint256 public ATTACK_CHANCE_DENOM;

    uint256 public randomMekaProbability;

    uint256[] public megaLevelProbabilities;

    uint256[] public mekaLevelSharePoints;
    uint256[] public megaTributePoints;

    uint256 public mekaTotalRewardPerPoint;
    uint256 public mekaTotalPointsStaked;

    uint256[][4] public megaStaked;

    mapping(uint256 => OogaAttributes) public oogaAttributes;

    mapping(uint256 => bool) public oogaEvolved;

    uint256 public publicMintAllowance;
    bool public publicMintStarted;
    mapping(address => uint256) public numberOfMintedOogas;

    uint256 public mintSaleAmount;
    bool public mintSale;
    bool public gameActive;

    uint256 public ogMinted;
    uint256 public maxOgSupply;
    uint256 public addedOgForRewardsAtEnd;

    uint256 public maxTokenSupply;

    uint256 public totalMintedRewardTokens;
    uint256 public maxMintedRewardTokens;

    uint256 public totalRandomTxFee;
    uint256 public totalRandomTxFeeWithdrawn;

    uint256 public totalMintETH;
    mapping(address => uint256) public withdrawerPercent;
    mapping(address => uint256) public withdrawerLastTotalMintETH;

    uint256 public nextRandomRequestId;
    mapping(uint256 => RandomRequest) public randomRequests;
    mapping(uint256 => MintRequest) public mintRequests;
    mapping(uint256 => ClaimRequest) public claimRequests;
    mapping(uint256 => uint256) public mergeRequests;
    uint256 public nextClaimWithoutRandomId;

    event MintMultipleRobo(address indexed account, uint256 indexed startFromTokenId, uint256 indexed amount);
    event MekaConvert(uint256 indexed tokenId);
    event OogaAttacked(uint256 indexed oogaId, address indexed tributeAccount, uint256 indexed tributeOogaId);
    event BabyOogaEvolve(address indexed account, uint256 indexed oogaId, uint256 indexed newTokenId);
    event StakeOoga(uint256 indexed oogaId, address indexed account);
    event UnstakeOoga(uint256 indexed oogaId, address indexed account);
    event ClaimReward(uint256 indexed claimId, address indexed account, uint256 indexed tokenId, uint256 amount);
    event TaxReward(uint256 indexed claimId, uint256 totalTax);
    event AttackReward(uint256 indexed claimId, uint256 indexed tokenId, uint256 amount);
    event LevelUpRoboOoga(address indexed account, uint256 indexed oogaId, uint256 indexed newLevel);
    event MergeMekaApes(address indexed account, uint256 indexed oogaIdSave, uint256 indexed oogaIdBurn);
    event MegaMerged(uint256 indexed tokenId, uint256 indexed megaLevel);

    event RequestRandoms(uint256 indexed requestId, uint256 requestSeed);
    event ReceiveRandoms(uint256 indexed requestId, uint256 entropy);

    //////////////////////////////////

    uint256 public previousBaseFee;
    uint256 public currentBaseFee;
    uint256 public baseFeeRefreshTime;
    uint256 public baseFeeUpdatedAt;

    event RoboMint(address indexed account, uint256 indexed tokenId);

    bool public initV2;

    //////////////////////////////////

    bool public allTokensMinted;
    uint256 public allMintedTimestamp;

    bool public ogRewardMinted;

    bool public initV3;

    //////////////////////////////////

    uint256[] public roboOogaRewardPerSec_midStage;

    bool public initV4;

    //////////////////////////////////

    event MakeCrew(address indexed account, uint256 indexed crewId);
    event RemoveCrew(uint256 indexed crewId);
    event ClaimCrewReward(address indexed account, uint256 indexed crewId, uint256 amount);

    uint256 public nextCrewId;
    mapping(uint256 => Crew) public crews;
    mapping(uint256 => uint256) public inCrew;

    uint256[] public roboLevelupPriceOG;
    uint256[] public roboOogaRewardPerSecInCrew;
    uint256[] public maxCrewForMekaLevel;
    uint256[] public mekaCrewRewardMultiplier;

    uint256 public crewClaimPercent;

    bool public initV5;

    event AddToCrew(uint256 indexed crewId, uint256 indexed tokenIds);
    event RemoveFromCrew(uint256 indexed crewId, uint256 indexed tokenIds);

    uint256 public unstakeCreditsStart;
    mapping(address => uint256) public unstakeCredits;
    mapping(address => uint256) public usedUnstakeCredits;
    uint256[] public unstakeCreditsForRoboLevel;

    uint256 public roboOogaRewardStart;

    mapping(address => uint256) public leaderboardRewardClaimed;

    event AddUnstakeCredits(address indexed user, uint256 indexed burnOogaId, uint256 addedCredits);
    event LeaderbordRewardClaim(address indexed user, uint256 reward);

    address public gameContract2;

    uint256 public midStageOverTimestamp;
    uint256 public roboOogaRewardEnd;
    uint256 public roboOogaRewardIncreaseDuration;

    event ChangeStaker(uint256 indexed tokenId, address indexed account);

    ///////////////////////////////////

    mapping(address => uint256) public recoverOGClaimed;
    address public recoverSigWallet;

    ///////////////////////////////////

    bool public initV6;
    uint256 public stopOGproductionTimestamp;

    ///////////////////////////////////

    function verifyMintSig(bytes memory message, uint8 _v, bytes32 _r, bytes32 _s, address sigWalletCheck) private pure returns (bool) {
        bytes32 messageHash = keccak256(message);
        bytes32 signedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = ecrecover(signedMessageHash, _v, _r, _s);
        return signer == sigWalletCheck;
    }

    function _ogMint(address toAddress, uint256 amount) private {
        uint256 toMint = amount;

        ogToken.mint(toAddress, toMint);
    }

    function claimAvailableAmount(uint256 tokenId) private view returns(uint256) {
        OogaAttributes memory ooga = oogaAttributes[tokenId];

        if (ooga.oogaType == OogaType.ROBOOOGA) {

            uint256 roboReward = ooga.savedReward;

            uint256 lastClaim = oogaAttributes[tokenId].lastClaimTimestamp;

            if (lastClaim < allMintedTimestamp) {
                roboReward += (allMintedTimestamp - lastClaim) * roboOogaRewardPerSec[ooga.level];
                lastClaim = allMintedTimestamp;
            }

            if (lastClaim < midStageOverTimestamp) {
                roboReward += (midStageOverTimestamp - lastClaim) * roboOogaRewardPerSec_midStage[ooga.level];
                lastClaim = midStageOverTimestamp;
            }

            uint256 lastTimestamp = (block.timestamp < stopOGproductionTimestamp) ? block.timestamp : stopOGproductionTimestamp;

            if (lastClaim < lastTimestamp) {
                uint256 passedTime = lastTimestamp - lastClaim;
                uint256 roboOogaRewardIncreasePerSecond = (roboOogaRewardEnd - roboOogaRewardStart) / roboOogaRewardIncreaseDuration;

                if (passedTime > roboOogaRewardIncreaseDuration) {

                    roboReward += (roboOogaRewardIncreaseDuration * roboOogaRewardIncreaseDuration * roboOogaRewardIncreasePerSecond) / 2;
                    roboReward += roboOogaRewardIncreaseDuration * roboOogaRewardStart;

                    roboReward += (passedTime - roboOogaRewardIncreaseDuration) * roboOogaRewardEnd;

                } else {
                    roboReward += (passedTime * passedTime * roboOogaRewardIncreasePerSecond) / 2;
                    roboReward += passedTime * roboOogaRewardStart;
                }

            }

            return roboReward;
        } else {
            
            return (mekaTotalRewardPerPoint - ooga.lastRewardPerPoint) * mekaLevelSharePoints[ooga.level];
        }
    }

    function _addMekaToStakingRewards(uint256 tokenId) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        mekaTotalPointsStaked += mekaLevelSharePoints[ooga.level];
        ooga.lastRewardPerPoint = mekaTotalRewardPerPoint;

        if (ooga.level > 0) {
            ooga.stakedMegaIndex = megaStaked[ooga.level].length;
            megaStaked[ooga.level].push(tokenId);
        }
    }

    function _removeMekaFromStakingRewards(uint256 tokenId) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        mekaTotalPointsStaked -= mekaLevelSharePoints[ooga.level];

        if (ooga.level > 0) {
            uint256 lastOogaId = megaStaked[ooga.level][ megaStaked[ooga.level].length - 1 ];
            megaStaked[ooga.level][ooga.stakedMegaIndex] = lastOogaId;
            megaStaked[ooga.level].pop();
            oogaAttributes[lastOogaId].stakedMegaIndex = ooga.stakedMegaIndex;
        }

        ooga.stakedMegaIndex = 0;
    }

    function createCrew(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");

        uint256 len = tokenIds.length;
        require(len > 0, "E120");

        uint256 crewId = nextCrewId;
        nextCrewId++;

        emit MakeCrew(msg.sender, crewId);

        Crew storage crew = crews[crewId];

        crew.owner = msg.sender;

        OogaAttributes storage mekaLeader = oogaAttributes[tokenIds[0]];

        require(mekaLeader.oogaType == OogaType.MEKAAPE, "E121");
        require(mekaLeader.staked == true && mekaLeader.stakedOwner == msg.sender, "E125");
        require(inCrew[tokenIds[0]] == 0, "E123");

        require(len-1 <= maxCrewForMekaLevel[mekaLeader.level], "E122");
       
        crew.oogas.push(tokenIds[0]);
        inCrew[tokenIds[0]] = crewId;
        emit AddToCrew(crewId, tokenIds[0]);

        uint256 mekaReward = claimAvailableAmount(tokenIds[0]);
        mekaLeader.lastRewardPerPoint = mekaTotalRewardPerPoint;

        _removeMekaFromStakingRewards(tokenIds[0]);

        _addToCrew(crewId, tokenIds, 1);

        crew.lastClaimTimestamp = block.timestamp;
        crew.savedReward = mekaReward;
    }

    function _removeCrew(uint256 crewId) private {
        Crew storage crew = crews[crewId];

        require(crew.owner == msg.sender, "E132");

        _claimCrewReward(crewId);

        for(uint256 i=1; i<crew.oogas.length; i++) {
            if (inCrew[crew.oogas[i]] == crewId) {
                _removeFromCrewOneToken(crewId, crew.oogas[i]);
            }
        }

        _addMekaToStakingRewards(crew.oogas[0]);
        inCrew[crew.oogas[0]] = 0;

        emit RemoveCrew(crewId);
    }

    function removeCrew(uint256[] calldata crewIds) external {
        require(gameActive, "E01");

        for(uint256 i=0; i<crewIds.length; i++) {
            _removeCrew(crewIds[i]);
        }
    }

    function _addToCrew(uint256 crewId, uint256[] calldata addTokenIds, uint256 startFrom) private {
        Crew storage crew = crews[crewId];

        for(uint256 i=startFrom; i<addTokenIds.length; i++) {
            OogaAttributes storage ooga = oogaAttributes[addTokenIds[i]];
            require(ooga.staked == true && ooga.stakedOwner == msg.sender, "E135");
            require(ooga.oogaType == OogaType.ROBOOOGA, "E133");
            require(inCrew[addTokenIds[i]] == 0, "E134");

            ooga.savedReward = claimAvailableAmount(addTokenIds[i]);
            ooga.lastClaimTimestamp = block.timestamp;

            crew.oogas.push(addTokenIds[i]);
            crew.totalRewardPerSec += roboOogaRewardPerSecInCrew[ooga.level];

            crew.oogaCount += 1;

            inCrew[addTokenIds[i]] = crewId;
            emit AddToCrew(crewId, addTokenIds[i]);
        }
    }

    function _removeFromCrewOneToken(uint256 crewId, uint256 tokenId) private {
        crews[crewId].totalRewardPerSec -= roboOogaRewardPerSecInCrew[oogaAttributes[tokenId].level];
        inCrew[tokenId] = 0;

        oogaAttributes[tokenId].lastClaimTimestamp = block.timestamp;

        crews[crewId].oogaCount -= 1;

        emit RemoveFromCrew(crewId, tokenId);
    }

    function _removeFromCrew(uint256 crewId, uint256[] calldata removeTokenIds) private {
         for(uint256 i=0; i<removeTokenIds.length; i++) {
            OogaAttributes storage ooga = oogaAttributes[removeTokenIds[i]];
            require(ooga.oogaType == OogaType.ROBOOOGA, "E143");
            require(inCrew[removeTokenIds[i]] == crewId, "E144");

            _removeFromCrewOneToken(crewId, removeTokenIds[i]);
         }
    }

    function changeCrew(uint256 crewId, uint256[] calldata addTokenIds, uint256[] calldata removeTokenIds) external {
        require(gameActive, "E01");

        Crew storage crew = crews[crewId];

        require(crew.owner == msg.sender, "E111");

        _updateCrewReward(crewId);

        uint256 maxCrewTokens = maxCrewForMekaLevel[oogaAttributes[crew.oogas[0]].level];
        require(crew.oogaCount + addTokenIds.length - removeTokenIds.length <= maxCrewTokens, "E112");

        _addToCrew(crewId, addTokenIds, 0);
        _removeFromCrew(crewId, removeTokenIds);
    }

function claimAvailableAmountCrew(uint256 crewId) public view returns(uint256) {
        Crew storage crew = crews[crewId];

        OogaAttributes storage mekaLeader = oogaAttributes[crew.oogas[0]];

        uint256 rewardPerSec = (crew.totalRewardPerSec * mekaCrewRewardMultiplier[mekaLeader.level]) / 100;

        uint256 crewReward = crew.savedReward;

        uint256 lastTimestamp = (block.timestamp < stopOGproductionTimestamp) ? block.timestamp : stopOGproductionTimestamp;

        if (crew.lastClaimTimestamp < lastTimestamp) {
            crewReward += (lastTimestamp - crew.lastClaimTimestamp) * rewardPerSec;
        }

        return crewReward;
    }

    function claimAvailableAmountMultipleCrews(uint256[] calldata crewIds) public view returns(uint256[] memory result) {
        result = new uint256[](crewIds.length);
        for(uint256 i=0; i<crewIds.length; i++) {
            result[i] = claimAvailableAmountCrew(crewIds[i]);
        }

        return result;
    }

    function _updateCrewReward(uint256 crewId) private {
        crews[crewId].savedReward = claimAvailableAmountCrew(crewId);
        crews[crewId].lastClaimTimestamp = block.timestamp;
    }

    function _claimCrewReward(uint256 crewId) private {

        Crew storage crew = crews[crewId];

        require(crew.owner == msg.sender, "E131");

        uint256 reward = claimAvailableAmountCrew(crewId);

        crew.lastClaimTimestamp = block.timestamp;
        crew.savedReward = 0;

        _ogMint(msg.sender, reward);

        emit ClaimCrewReward(msg.sender, crewId, reward);
    }

    function claimCrewReward(uint256[] calldata crewIds) external {
        require(gameActive, "E01");

        for(uint256 i=0; i<crewIds.length; i++) {
            _claimCrewReward(crewIds[i]);
        }
    }

    function claimLeaderbordReward(LeaderboardRewardSignature calldata rewardSig) external {
        require(gameActive, "E01");

        require(verifyMintSig(
                abi.encode(msg.sender, rewardSig.reward),
                rewardSig._v,
                rewardSig._r,
                rewardSig._s,
                mintSigWallet
            ), "E181");

        require(leaderboardRewardClaimed[msg.sender] == 0, "E182");

        leaderboardRewardClaimed[msg.sender] = rewardSig.reward;

        _ogMint(msg.sender, rewardSig.reward);

        emit LeaderbordRewardClaim(msg.sender, rewardSig.reward);
    }

    function recoverLostTokens(uint256[] calldata tokenIds, address oldOwner, address newOwner) external onlyOwner {
        for(uint256 i=0; i<tokenIds.length; i++) {
            OogaAttributes storage ooga = oogaAttributes[tokenIds[i]];
            require(ooga.staked == true && ooga.stakedOwner == oldOwner, "E510");
            if (inCrew[tokenIds[i]] != 0) {
                _removeFromCrewOneToken(inCrew[tokenIds[i]], tokenIds[i]);
            }
            ooga.stakedOwner = newOwner;
            emit ChangeStaker(tokenIds[i], newOwner);
        }
    }

    function changeRecoverSigWallet(address newRecoveryWallet_) external onlyOwner {
        recoverSigWallet = newRecoveryWallet_;
    }

    function recoverLostOG(LeaderboardRewardSignature calldata rewardSig) external {
        require(gameActive, "E01");

        require(verifyMintSig(
                abi.encode(msg.sender, rewardSig.reward),
                rewardSig._v,
                rewardSig._r,
                rewardSig._s,
                recoverSigWallet
            ), "E281");

        require(recoverOGClaimed[msg.sender] == 0, "E282");

        recoverOGClaimed[msg.sender] = rewardSig.reward;

        _ogMint(msg.sender, rewardSig.reward);

        emit ClaimReward(0, msg.sender, 0, rewardSig.reward);
    }

    function withdrawERC20(IERC20 token, address toAddress, uint256 amount) external onlyOwner {
        token.transfer(toAddress, amount);
    }

    function withdrawERC721(IERC721 token, address toAddress, uint256 tokenId) external onlyOwner {
        token.transferFrom(address(this), toAddress, tokenId);
    }
}