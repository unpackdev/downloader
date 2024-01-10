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

contract MekaApesGame_1 is OwnableUpgradeable {

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

    event MintMultipleRobo(address indexed account, uint256 startFromTokenId, uint256 amount);
    event MekaConvert(uint256 indexed tokenId);
    event OogaAttacked(uint256 indexed oogaId, address indexed tributeAccount, uint256 tributeOogaId);
    event BabyOogaEvolve(address indexed account, uint256 indexed oogaId, uint256 indexed newTokenId);
    event StakeOoga(uint256 indexed oogaId, address indexed account);
    event UnstakeOoga(uint256 indexed oogaId, address indexed account);
    event ClaimReward(uint256 indexed claimId, address indexed account, uint256 indexed tokenId, uint256 amount);
    event TaxReward(uint256 indexed claimId, uint256 totalTax);
    event AttackReward(uint256 indexed claimId, uint256 indexed tokenId, uint256 amount);
    event LevelUpRoboOoga(address indexed account, uint256 indexed oogaId, uint256 newLevel);
    event MergeMekaApes(address indexed account, uint256 oogaIdSave, uint256 indexed oogaIdBurn);
    event MegaMerged(uint256 indexed tokenId, uint256 megaLevel);

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

    //////////////////////////////////

    function initialize_stage15_1(
        address gameContract2_,
        uint256 roboOogaRewardStart_,
        uint256 roboOogaRewardEnd_,
        uint256 roboOogaRewardIncreaseDuration_,
        uint256 newMergePrice_,
        uint256 newRandomMekaProbability_
    ) public onlyOwner {
        require(!initV5, "E90");
        gameContract2 = gameContract2_;

        roboOogaRewardStart = roboOogaRewardStart_;
        roboOogaRewardEnd = roboOogaRewardEnd_;
        roboOogaRewardIncreaseDuration = roboOogaRewardIncreaseDuration_;

        prices.mekaMergePrice = newMergePrice_;
        randomMekaProbability = newRandomMekaProbability_;
    }

    function initialize_stage15_2(
        uint256[] calldata roboLevelupPrice_,
        uint256[] calldata roboLevelupPriceOG_,
        uint256[] calldata maxCrewForMekaLevel_,
        uint256[] calldata roboOogaRewardPerSecInCrew_,
        uint256[] calldata mekaCrewRewardMultiplier_,
        uint256[] calldata unstakeCreditsForRoboLevel_
    ) public onlyOwner {
        require(!initV5, "E90");
        initV5 = true;

        prices.roboLevelupPrice = roboLevelupPrice_;
        roboLevelupPriceOG = roboLevelupPriceOG_;
        maxCrewForMekaLevel = maxCrewForMekaLevel_;
        roboOogaRewardPerSecInCrew = roboOogaRewardPerSecInCrew_;
        mekaCrewRewardMultiplier = mekaCrewRewardMultiplier_;

        unstakeCreditsForRoboLevel = unstakeCreditsForRoboLevel_;

        nextCrewId = 1;
        unstakeCreditsStart = 5;

        midStageOverTimestamp = block.timestamp;
    }

    function changeContract2(address gameContract2_) external onlyOwner {
        gameContract2 = gameContract2_;
    }

    function changePrices(Prices memory prices_) external onlyOwner {
        prices = prices_;
    }

    function changeGameActive(bool gameActive_) external onlyOwner {
        gameActive = gameActive_;
    }

    function changeRandomsGas(RandomsGas memory randomsGas_) external onlyOwner {
        randomsGas = randomsGas_;
    }

    function changeMintOGPriceSteps(uint256[] calldata mintOGpriceSteps_) external onlyOwner {
        mintOGpriceSteps = mintOGpriceSteps_;
    }

    function changeRoboParameters(
        uint256[] calldata roboOogaRewardPerSec_,
        uint256[] calldata roboOogaMinimalRewardToUnstake_,
        uint256[] calldata roboOogaRewardAttackProbabilities_
    )
        external onlyOwner
    {
        roboOogaRewardPerSec = roboOogaRewardPerSec_;
        roboOogaMinimalRewardToUnstake = roboOogaMinimalRewardToUnstake_;
        roboOogaRewardAttackProbabilities = roboOogaRewardAttackProbabilities_;
    }

    function changeMekaParameters(
        uint256[] calldata megaLevelProbabilities_,
        uint256[] calldata mekaLevelSharePoints_,
        uint256[] calldata megaTributePoints_
    )
        external onlyOwner
    {
        megaLevelProbabilities = megaLevelProbabilities_;
        mekaLevelSharePoints = mekaLevelSharePoints_;
        megaTributePoints = megaTributePoints_;
    }

    function changeSettings(
        uint256 claimTax_,
        uint256 maxMintWithDMT_,
        uint256 mintSaleAmount_,
        uint256 maxTokenSupply_,
        uint256 maxOgSupply_,
        uint256 addedOgForRewardsAtEnd_,
        uint256 ethMintAttackChance_,
        uint256 dmtMintAttackChance_,
        uint256 ogMintAttackChance_,
        uint256 randomMekaProbability_
    ) 
        external onlyOwner 
    {
        claimTax = claimTax_;
        maxMintWithDMT = maxMintWithDMT_;
        mintSaleAmount = mintSaleAmount_;
        maxTokenSupply = maxTokenSupply_;
        maxOgSupply = maxOgSupply_;
        addedOgForRewardsAtEnd = addedOgForRewardsAtEnd_;
        ethMintAttackChance = ethMintAttackChance_;
        dmtMintAttackChance = dmtMintAttackChance_;
        ogMintAttackChance = ogMintAttackChance_;
        randomMekaProbability = randomMekaProbability_;
    }

    function changeBaseFeeRefreshTime(uint256 baseFeeRefreshTime_) external onlyOwner {
        baseFeeRefreshTime = baseFeeRefreshTime_;
    }

    function totalMintedTokens() public view returns(uint256) {
        return nextTokenId - 1;
    } 

    function getPrices() public view returns(PricesGetter memory) {
        return PricesGetter(
            prices.mintPrice,
            prices.mintStakePrice,
            prices.mintOGprice[ currentOgPriceStep ],
            prices.mintOGstakePrice[ currentOgPriceStep ],
            prices.mintDMTstakePrice,
            prices.roboLevelupPrice,
            prices.mekaMergePrice,
            roboLevelupPriceOG
        );
    }

    function _mintRandomTotalGas(uint256 amount, bool staking) private view returns(uint256) {
        return randomsGas.mintBase + amount*randomsGas.mintPerToken + (staking ? (amount-1)*randomsGas.mintPerTokenStaked : 0);
    }

    function mintRandomGas(uint256 amount, bool staking) public view returns(uint256) {
        return currentBaseFee * _mintRandomTotalGas(amount, staking);
    }

    function _mergeRandomTotalGas() private view returns(uint256) {
        return randomsGas.mergeBase;
    }

    function mergeRandomGas() public view returns(uint256) {
        return currentBaseFee * _mergeRandomTotalGas();
    }

    function _updateAndGetBaseFee() private returns(uint256) {
        if (block.timestamp - baseFeeUpdatedAt > baseFeeRefreshTime) {
            previousBaseFee = currentBaseFee;
            currentBaseFee = block.basefee;
            baseFeeUpdatedAt = block.timestamp;
        }

        if (previousBaseFee < currentBaseFee) return previousBaseFee;
        return currentBaseFee;
    } 

    function _getNextRandom(uint256 maxNumber, uint256 entropy, uint256 bits) private pure returns (uint256, uint256) {
        uint256 maxB = (uint256(1)<<bits);
        if (entropy < maxB) entropy = uint256(keccak256(abi.encode(entropy)));
        uint256 rnd = (entropy & (maxB - 1)) % maxNumber;
        return (rnd, entropy >> bits);
    }

    function _getNextRandomProbability(uint256 entropy) private pure returns (uint256, uint256) {
        if (entropy < 1048576) entropy = uint256(keccak256(abi.encode(entropy)));
        return(entropy & 1023, entropy >> 10);
    }

    function requestRandoms() internal returns (uint256) {
        emit RequestRandoms(nextRandomRequestId, nextRandomRequestId);
        nextRandomRequestId++;
        return nextRandomRequestId - 1;
    }

    function _receiveRandoms(uint256 requestId, uint256 entropy) private {
        emit ReceiveRandoms(requestId, entropy);

        RandomRequest storage request = randomRequests[requestId];

        if(!request.active) return;

        request.active = false;

        if (request.requestType == RandomRequestType.MINT) {
            receiveMintRandoms(request.user, requestId, entropy);
        } else if (request.requestType == RandomRequestType.MERGE) {
            receiveMergeRandoms(requestId, entropy);
        }
    }

    function receiveRandoms(uint256 requestId, uint256 entropy) external { 
        require(msg.sender == randomProvider, "E60");
        _receiveRandoms(requestId, entropy);
    }

    function receiveMultipleRandoms(uint256[] calldata requestIds, uint256[] calldata entropies) external {
        require(msg.sender == randomProvider, "E60");

        uint256 length = requestIds.length;
        for(uint256 i=0; i<length; i++) {
            _receiveRandoms(requestIds[i], entropies[i]);
        }

        uint256 randomTxFeeAmount = totalRandomTxFee - totalRandomTxFeeWithdrawn;
        if (randomTxFeeAmount > 0.3 ether) {
            totalRandomTxFeeWithdrawn += randomTxFeeAmount;
            payable(randomProvider).transfer(randomTxFeeAmount);
        }
    }

    function withdrawRandomTxFee(uint256 amount) external {
        require(msg.sender == randomProvider, "E99");
        require(totalRandomTxFee - totalRandomTxFeeWithdrawn <= amount, "E98");
        totalRandomTxFeeWithdrawn += amount;
        payable(randomProvider).transfer(amount);
    } 

    function _ogMint(address toAddress, uint256 amount) private {

        uint256 toMint = amount;

        ogToken.mint(toAddress, toMint);
    }

    function _mintMekaOoga(address toAddress) private returns (uint256) {

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        if (nextTokenId >= mintOGpriceSteps[currentOgPriceStep]) {
            currentOgPriceStep++;
        }

        erc721Contract.mint(toAddress, tokenId);

        oogaAttributes[tokenId].oogaType = OogaType.MEKAAPE;
        oogaAttributes[tokenId].level = 0;
        
        return tokenId;
    }

    function _mintMultipleRoboOoga(address toAddress, uint256 amount) private returns(uint256) {

        uint256 startFromTokenId = nextTokenId;

        nextTokenId += amount;

        if (nextTokenId >= mintOGpriceSteps[currentOgPriceStep]) {
            currentOgPriceStep++;
        }

        erc721Contract.mintMultiple(toAddress, startFromTokenId, amount);

        for(uint256 i=0; i<amount; i++) {
            oogaAttributes[startFromTokenId + i].level = 1;
        }

        emit MintMultipleRobo(toAddress, startFromTokenId, amount);

        return startFromTokenId;
    }  

    function requestMintRoboOogas(address toAddress, uint256 amount, bool toStake, uint256 attackChance) private { 
        
        uint256 randomsAmount;
        if (attackChance > 0) {
            randomsAmount = 2*amount;
        } else {
            randomsAmount = amount;
        }

        uint256 requestId = requestRandoms();
        randomRequests[requestId] = RandomRequest(RandomRequestType.MINT, toAddress, true);
        mintRequests[requestId] = MintRequest(uint32(nextTokenId), uint8(amount), uint8(attackChance), toStake);

        _mintMultipleRoboOoga(address(this), amount);
    }

    function getTotalMegaTributePointsStaked() private view returns(uint256) {
        uint256 totalTributePoints = 0;
        for(uint256 i=1; i<=3; i++) {
            totalTributePoints += megaTributePoints[i] * megaStaked[i].length;
        }
        return totalTributePoints;
    }

    function _getStakedMega(uint256 rndTributePoint) private view returns(uint256) {
        uint256 totalSum = 0;
        for(uint256 i=1; i<=3; i++) {
            uint256 levelSum = megaTributePoints[i] * megaStaked[i].length;

            if (rndTributePoint < totalSum + levelSum) {
                uint256 pickedIndex = (rndTributePoint - totalSum) / megaTributePoints[i];
                return megaStaked[i][pickedIndex];
            }

            totalSum += levelSum;
        }

        return 0;
    }

    function attackOogaMint(uint256 tokenId, uint256 totalTributePointStaked, uint256 entropy) private returns (uint256) {
        
        uint256 rndTributePoint; 

        (rndTributePoint, entropy) = _getNextRandom(totalTributePointStaked, entropy, 25);
        
        uint256 payTributeOoga = _getStakedMega(rndTributePoint);

        erc721Contract.transferFrom(address(this), oogaAttributes[payTributeOoga].stakedOwner, tokenId);
        emit OogaAttacked(tokenId, oogaAttributes[payTributeOoga].stakedOwner, payTributeOoga);
        
        return entropy;
    }

    function receiveMintRandoms(address user, uint256 requestId, uint256 entropy) private { 

        uint256 rnd;

        MintRequest storage mintReq = mintRequests[requestId];

        for(uint256 tokenId = mintReq.startFromId; tokenId < mintReq.startFromId + mintReq.amount; tokenId++) {

            OogaAttributes storage ooga = oogaAttributes[tokenId];

            (rnd, entropy) = _getNextRandomProbability(entropy);

            if (rnd < randomMekaProbability) {
                ooga.oogaType = OogaType.MEKAAPE;
                ooga.level = 0;
                emit MekaConvert(tokenId);
            } else {
                emit RoboMint(user, tokenId);
            }

            bool attacked = false;

            if (mintReq.attackChance > 0) {
                (rnd, entropy) = _getNextRandomProbability(entropy);
                if (rnd < mintReq.attackChance) {
                    uint256 totalTributePointStaked = getTotalMegaTributePointsStaked();
                    if (totalTributePointStaked > 0) {
                        entropy = attackOogaMint(tokenId, totalTributePointStaked, entropy);
                        attacked = true;
                    }
                }
            }

            if (!attacked) {
                if (mintReq.toStake) {
                    _stakeToken(tokenId, user, true);
                } else {
                    erc721Contract.transferFrom(address(this), user, tokenId);
                }
            }
        }
    }   

    function isBabyOogaEvolved(uint256 oogaId) public view returns(bool) {
        return oogaEvolved[oogaId];
    }

    function _evolveBabyOoga(uint256 oogaId) private {

        require(oogaId >= 2002001, "E11");
        require(oogaEvolved[oogaId] == false, "E12");
        require(oogaVerse.ownerOf(oogaId) == msg.sender, "E13");

        oogaEvolved[oogaId] = true;

        uint256 newTokenId = _mintMekaOoga(msg.sender);

        emit BabyOogaEvolve(msg.sender, oogaId, newTokenId); 
    }

    function evolveBabyOogas(uint256[] calldata tokenIds) external {
        require(!mintSale && gameActive, "E01");

        for(uint256 i=0; i<tokenIds.length; i++) {
            _evolveBabyOoga(tokenIds[i]);
        }
    }

    function mintRewardTokens(address toAddress, uint256 amount) external onlyOwner {
        require(amount + totalMintedRewardTokens <= maxMintedRewardTokens, "E97");
        totalMintedRewardTokens += amount;

        requestMintRoboOogas(toAddress, amount, false, 0);
    }

    function mintWithOG(uint256 amount, bool toStake) external payable {
        require(!mintSale && gameActive, "E01");
        require(totalMintedTokens() + amount <= maxTokenSupply, "E31");

        uint256 gasFee = _updateAndGetBaseFee();
        require(msg.value >= _mintRandomTotalGas(amount, toStake) * gasFee, "E33");
        totalRandomTxFee += msg.value;

        uint256 price;
        if (toStake) {
            price = prices.mintOGstakePrice[currentOgPriceStep];
        } else {
            price = prices.mintOGprice[currentOgPriceStep];
        }
        
        ogToken.transferFrom(msg.sender, address(this), price * amount);

        requestMintRoboOogas(msg.sender, amount, toStake, ogMintAttackChance);
    }

    function mintWithDMT(uint256 amount) external payable {
        require(!mintSale && gameActive, "E01");
        require(totalMintedTokens() + amount <= maxTokenSupply, "E32");
        require(tokensMintedWithDMT + amount <= maxMintWithDMT, "E51");

        uint256 gasFee = _updateAndGetBaseFee();
        require(msg.value >= _mintRandomTotalGas(amount, true) * gasFee, "E34");
        totalRandomTxFee += msg.value;

        dmtToken.transferFrom(msg.sender, address(this), prices.mintDMTstakePrice * amount);

        requestMintRoboOogas(msg.sender, amount, true, dmtMintAttackChance);

        tokensMintedWithDMT += amount;
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

    function _stakeToken(uint256 tokenId, address stakedOwner, bool minting) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        if (!minting) {
            erc721Contract.transferFrom(stakedOwner, address(this), tokenId);
        }

        ooga.staked = true;
        ooga.stakedOwner = stakedOwner;
        ooga.lastClaimTimestamp = block.timestamp;
        ooga.savedReward = 0;

        if (ooga.oogaType == OogaType.MEKAAPE) {
            _addMekaToStakingRewards(tokenId);
        }

        emit StakeOoga(tokenId, stakedOwner);
    }

    function stake(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");

        for(uint256 i=0; i<tokenIds.length; i++) {
            require(erc721Contract.ownerOf(tokenIds[i]) == msg.sender, "E41");
            _stakeToken(tokenIds[i], msg.sender, false);
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

    function _unstakeToken(uint256 tokenId) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        address oogaOwner = ooga.stakedOwner;

        ooga.staked = false;
        ooga.stakedOwner = address(0x0);

        if (ooga.oogaType == OogaType.MEKAAPE) {
            _removeMekaFromStakingRewards(tokenId);
        } else if (ooga.oogaType == OogaType.ROBOOOGA) {
            usedUnstakeCredits[oogaOwner] += 1;
        }

        erc721Contract.transferFrom(address(this), oogaOwner, tokenId);

        emit UnstakeOoga(tokenId, oogaOwner);
    }

    function unstake(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");

        require(tokenIds.length <= getUnstakeCreditsForAddress(msg.sender), "E161");

        _claim(tokenIds, true);
    }

    function burnOogaForUnstakeCredits(uint256[] calldata tokenIds) external {
        for(uint256 i=0; i<tokenIds.length; i++) {
            OogaAttributes storage ooga = oogaAttributes[tokenIds[i]];

            _burnRoboOoga(tokenIds[i]);

            unstakeCredits[msg.sender] += unstakeCreditsForRoboLevel[ooga.level];

            emit AddUnstakeCredits(msg.sender, tokenIds[i], unstakeCreditsForRoboLevel[ooga.level]);
        }
    }

    function getUnstakeCreditsForAddress(address user) view public returns(uint256) {
        return unstakeCreditsStart + unstakeCredits[user] - usedUnstakeCredits[user];
    }

    function _addMekaRewards(uint256 amount) private {
        _ogMint(address(this), amount);
        if(mekaTotalPointsStaked > 0){
            mekaTotalRewardPerPoint += amount / mekaTotalPointsStaked;
        }
    }

    function _claim(uint256[] calldata tokenIds, bool unstaking) private { 
        uint256 totalRoboReward = 0;
        uint256 totalMekaReward = 0;
        uint256 totalTax = 0;

        nextClaimWithoutRandomId++;
        uint256 claimId = nextClaimWithoutRandomId;

        for(uint256 i=0; i<tokenIds.length; i++) {

            OogaAttributes storage ooga = oogaAttributes[tokenIds[i]];
            require(ooga.staked == true && ooga.stakedOwner == msg.sender, "E91");
            require(inCrew[tokenIds[i]] == 0, "E912");

            uint256 reward = claimAvailableAmount(tokenIds[i]);

            if (ooga.oogaType == OogaType.ROBOOOGA) {
                uint256 taxable = (reward * claimTax) / 100;
                totalRoboReward += reward - taxable;
                totalTax += taxable;

                ooga.lastClaimTimestamp = block.timestamp;

                emit ClaimReward(claimId, msg.sender, tokenIds[i], reward - taxable);

            } else {
                totalMekaReward += reward;
                
                ooga.lastRewardPerPoint = mekaTotalRewardPerPoint;

                emit ClaimReward(claimId, msg.sender, tokenIds[i], reward);
            }

            if (unstaking) {
                _unstakeToken(tokenIds[i]);
            }

            ooga.savedReward = 0;
        }

        _ogMint(msg.sender, totalMekaReward+totalRoboReward);

        if (totalTax > 0) {
            _addMekaRewards(totalTax);
            emit TaxReward(claimId, totalTax);
        }
    }

    function claimReward(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");
        _claim(tokenIds, false);
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

            uint256 passedTime = block.timestamp - lastClaim;
            uint256 roboOogaRewardIncreasePerSecond = (roboOogaRewardEnd - roboOogaRewardStart) / roboOogaRewardIncreaseDuration;

            if (passedTime > roboOogaRewardIncreaseDuration) {

                roboReward += (roboOogaRewardIncreaseDuration * roboOogaRewardIncreaseDuration * roboOogaRewardIncreasePerSecond) / 2;
                roboReward += roboOogaRewardIncreaseDuration * roboOogaRewardStart;

                roboReward += (passedTime - roboOogaRewardIncreaseDuration) * roboOogaRewardEnd;

            } else {
                roboReward += (passedTime * passedTime * roboOogaRewardIncreasePerSecond) / 2;
                roboReward += passedTime * roboOogaRewardStart;
            }

            return roboReward;
        } else {
            
            return (mekaTotalRewardPerPoint - ooga.lastRewardPerPoint) * mekaLevelSharePoints[ooga.level];
        }
    }

    function claimAvailableAmountMultipleTokens(uint256[] calldata tokenIds) public view returns(uint256[] memory result) {
        result = new uint256[](tokenIds.length);
        for(uint256 i=0; i<tokenIds.length; i++) {
            result[i] = claimAvailableAmount(tokenIds[i]);
        }

        return result;
    }

    function _burnRoboOoga(uint256 burnTokenId) private {
        OogaAttributes storage burnOoga = oogaAttributes[burnTokenId];
        require(erc721Contract.ownerOf(burnTokenId) == msg.sender || burnOoga.stakedOwner == msg.sender , "E722");
        require(burnOoga.oogaType == OogaType.ROBOOOGA, "E712");

        if (inCrew[burnTokenId] > 0) {
            _updateCrewReward(inCrew[burnTokenId]);
            _removeFromCrewOneToken(inCrew[burnTokenId], burnTokenId);
        } 
        
        if (burnOoga.staked) {
            _ogMint(msg.sender, claimAvailableAmount(burnTokenId));
        }

        burnOoga.staked = false;
        burnOoga.stakedOwner = address(0x0);
        erc721Contract.burn(burnTokenId);
    }

    function _levelUpRoboOoga(uint256 tokenId, bool payWithDMT, uint256 burnTokenId) private {
        require(!mintSale && gameActive, "E01");

        OogaAttributes storage ooga = oogaAttributes[tokenId];
        require(erc721Contract.ownerOf(tokenId) == msg.sender || ooga.stakedOwner == msg.sender , "E72");
        require(ooga.oogaType == OogaType.ROBOOOGA && ooga.level < 6, "E71");

        require(tokenId != burnTokenId, "E730");

        if (inCrew[tokenId] > 0) {

            _updateCrewReward(inCrew[tokenId]);
            crews[inCrew[tokenId]].totalRewardPerSec += (roboOogaRewardPerSecInCrew[ooga.level + 1] - roboOogaRewardPerSecInCrew[ooga.level]);

        } else if (ooga.staked) {
            ooga.savedReward = claimAvailableAmount(tokenId);
            ooga.lastClaimTimestamp = block.timestamp;
        }

        if (payWithDMT) {
            dmtToken.transferFrom(msg.sender, address(this), prices.roboLevelupPrice[ooga.level]);
        } else {
            ogToken.transferFrom(msg.sender, address(this), roboLevelupPriceOG[ooga.level]);

            _burnRoboOoga(burnTokenId);
        }

        ooga.level++;

        emit LevelUpRoboOoga(msg.sender, tokenId, ooga.level);
    }

    function levelUpRoboOoga(uint256 tokenId, uint256 numberOfLevels) external {
        for(uint256 i=0; i<numberOfLevels; i++) {
            _levelUpRoboOoga(tokenId, true, 0);
        }
    }

    function levelUpRoboOogaWithOG(uint256 tokenId, uint256 numberOfLevels, uint256[] calldata burnTokenIds) external {
        require(burnTokenIds.length == numberOfLevels, "E151");
        for(uint256 i=0; i<numberOfLevels; i++) {
            _levelUpRoboOoga(tokenId, false, burnTokenIds[i]);
        }
    }

    function _getMegaLevel(uint256 rnd) private view returns(uint8) {
        for(uint8 i=0; i<3; i++) {
            if (rnd < megaLevelProbabilities[i]) return 1+i;
        }
        
        return 0;
    }

    function receiveMergeRandoms(uint256 requestId, uint256 entropy) private { 
        uint256 tokenId = mergeRequests[requestId];

        OogaAttributes storage ooga =  oogaAttributes[tokenId];

        uint256 rnd;
        (rnd, entropy) = _getNextRandomProbability(entropy);
        ooga.level = _getMegaLevel(rnd);

        if (ooga.staked == true) {
            mekaTotalPointsStaked += mekaLevelSharePoints[ooga.level] - mekaLevelSharePoints[0];
            
            ooga.stakedMegaIndex = megaStaked[ooga.level].length;
            megaStaked[ooga.level].push(tokenId);
        }

        emit MegaMerged(tokenId, ooga.level);
    }

    function requestMergeMeka(uint256 tokenId) private {
        uint256 requestId = requestRandoms();
        randomRequests[requestId] = RandomRequest(RandomRequestType.MERGE, msg.sender, true);
        mergeRequests[requestId] = tokenId;
    }

    function mergeMekaApes(uint256 tokenIdSave, uint256 tokenIdBurn) external payable {
        require(!mintSale && gameActive, "E01");
        require(tokenIdSave != tokenIdBurn, "E81");

        uint256 gasFee = _updateAndGetBaseFee();
        require(msg.value >= _mergeRandomTotalGas() * gasFee, "E36");
        totalRandomTxFee += msg.value;

        OogaAttributes storage oogaSave = oogaAttributes[tokenIdSave];
        OogaAttributes storage oogaBurn = oogaAttributes[tokenIdBurn];

        require(erc721Contract.ownerOf(tokenIdSave) == msg.sender || (oogaSave.staked && oogaSave.stakedOwner == msg.sender), "E84");
        require(erc721Contract.ownerOf(tokenIdBurn) == msg.sender || (oogaBurn.staked && oogaBurn.stakedOwner == msg.sender), "E85");

        require(inCrew[tokenIdSave] == 0 && inCrew[tokenIdBurn] == 0, "E811");

        require(oogaSave.oogaType == OogaType.MEKAAPE && oogaBurn.oogaType == OogaType.MEKAAPE, "E82");
        require(oogaSave.level == 0 && oogaBurn.level == 0, "E83");

        uint256 reward = 0;
        if (oogaSave.staked == true) {
            uint256 rewardAvailable = claimAvailableAmount(tokenIdSave);
            reward += rewardAvailable;
            oogaSave.lastRewardPerPoint = mekaTotalRewardPerPoint;
            emit ClaimReward(nextRandomRequestId, msg.sender, tokenIdSave, rewardAvailable);
        }

        if (oogaBurn.staked == true) {
            uint256 rewardAvailable = claimAvailableAmount(tokenIdBurn);
            reward += rewardAvailable;
            oogaBurn.lastRewardPerPoint = mekaTotalRewardPerPoint;
            emit ClaimReward(nextRandomRequestId, msg.sender, tokenIdBurn, rewardAvailable);
            _unstakeToken(tokenIdBurn);
        }

        if (prices.mekaMergePrice > reward) {
            ogToken.transferFrom(msg.sender, address(this), prices.mekaMergePrice - reward);
        } else {
            _ogMint(msg.sender, reward - prices.mekaMergePrice);
        }

        requestMergeMeka(tokenIdSave);

        erc721Contract.burn(tokenIdBurn);

        emit MergeMekaApes(msg.sender, tokenIdSave, tokenIdBurn);
    }

    function _updateCrewReward(uint256 crewId) private {
        crews[crewId].savedReward = claimAvailableAmountCrew(crewId);
        crews[crewId].lastClaimTimestamp = block.timestamp;
    }

    function claimAvailableAmountCrew(uint256 crewId) public view returns(uint256) {
        Crew storage crew = crews[crewId];

        OogaAttributes storage mekaLeader = oogaAttributes[crew.oogas[0]];

        uint256 rewardPerSec = (crew.totalRewardPerSec * mekaCrewRewardMultiplier[mekaLeader.level]) / 100;

        return crew.savedReward + (block.timestamp - crew.lastClaimTimestamp) * rewardPerSec;
    }

    function _removeFromCrewOneToken(uint256 crewId, uint256 tokenId) private {
        crews[crewId].totalRewardPerSec -= roboOogaRewardPerSecInCrew[oogaAttributes[tokenId].level];
        inCrew[tokenId] = 0;

        oogaAttributes[tokenId].lastClaimTimestamp = block.timestamp;

        crews[crewId].oogaCount -= 1;

        emit RemoveFromCrew(crewId, tokenId);
    }

    function _delegateToNextContract() private {
        address implementation = gameContract2;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable virtual {
        _delegateToNextContract();
    }

    function withdrawERC20(IERC20 token, address toAddress, uint256 amount) external onlyOwner {
        token.transfer(toAddress, amount);
    }

    function withdrawERC721(IERC721 token, address toAddress, uint256 tokenId) external onlyOwner {
        token.transferFrom(address(this), toAddress, tokenId);
    }
}