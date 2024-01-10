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

contract MekaApesGame is OwnableUpgradeable {

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

    /*
    function initialize(
        InitParams calldata initParams
    ) public initializer {
        __Ownable_init();

        erc721Contract = initParams.erc721Contract_;
        ogToken = initParams.ogToken_;
        dmtToken = initParams.dmtToken_;
        oogaVerse = initParams.oogaVerse_;

        mintSigWallet = initParams.mintSigWallet_;
        randomProvider = initParams.randomProvider_;

        nextRandomRequestId = 1;
        nextClaimWithoutRandomId = 100000000;

        nextTokenId = 1;

        tokensMintedWithDMT = 0;

        maxMintWithDMT = initParams.maxMintWithDMT_;
        mintSaleAmount = initParams.mintSaleAmount_;
        maxTokenSupply = initParams.maxTokenSupply_;

        ogMinted = 0;
        maxOgSupply = initParams.maxOgSupply_;
        addedOgForRewardsAtEnd = initParams.addedOgForRewardsAtEnd_;

        ethMintAttackChance = initParams.ethMintAttackChance_;
        dmtMintAttackChance = initParams.dmtMintAttackChance_;
        ogMintAttackChance = initParams.ogMintAttackChance_;

        randomMekaProbability = initParams.randomMekaProbability_;

        mintSale = true;
        gameActive = true;  

        publicMintAllowance = initParams.publicMintAllowance_;
        publicMintStarted = false;

        totalMintedRewardTokens = 0;
        maxMintedRewardTokens = initParams.maxMintedRewardTokens_;

        mekaTotalRewardPerPoint = 0;
        mekaTotalPointsStaked = 0;
        megaLevelProbabilities = initParams.megaLevelProbabilities_;
        mekaLevelSharePoints = initParams.mekaLevelSharePoints_;
        megaTributePoints = initParams.megaTributePoints_;

        prices = initParams.prices_;
        randomsGas = initParams.randomsGas_;

        totalRandomTxFee = 0;
        totalRandomTxFeeWithdrawn = 0;

        mintOGpriceSteps = initParams.mintOGpriceSteps_;
        currentOgPriceStep = 1;

        roboOogaRewardPerSec = initParams.roboOogaRewardPerSec_;
        roboOogaMinimalRewardToUnstake = initParams.roboOogaMinimalRewardToUnstake_;
        roboOogaRewardAttackProbabilities = initParams.roboOogaRewardAttackProbabilities_;

        claimTax = initParams.claimTax_;

        for(uint256 i=0; i<initParams.mintETHWithdrawers_.length; i++) {
            withdrawerPercent[initParams.mintETHWithdrawers_[i]] = initParams.mintETHWithdrawersPercents_[i];
            withdrawerLastTotalMintETH[initParams.mintETHWithdrawers_[i]] = 0;
        }
    }

    function initialize_v2() public onlyOwner {
        require(!initV2, "E90");
        initV2 = true;
        maxMintedRewardTokens = 200;
        previousBaseFee = block.basefee;
        currentBaseFee = block.basefee;
        baseFeeUpdatedAt = block.timestamp;
        baseFeeRefreshTime = 900;
    }
    

    function initialize_v3() public onlyOwner {
        require(!initV3, "E90");
        initV3 = true;
        allTokensMinted = false;
        allMintedTimestamp = 0;
        ogRewardMinted = false;
    }
    */

    function initialize_v4(uint256[] calldata roboOogaRewardPerSec_midStage_, uint256 maxTokenSupply_, uint256 maxMintWithDMT_) public onlyOwner {
        require(!initV4, "E90");
        initV4 = true;
        roboOogaRewardPerSec_midStage = roboOogaRewardPerSec_midStage_;
        maxTokenSupply = maxTokenSupply_;
        maxMintWithDMT = maxMintWithDMT_;
    }

    function changePrices(Prices memory prices_) external onlyOwner {
        prices = prices_;
    }

    function changePublicMintStarted(bool publicMintStarted_) external onlyOwner {
        publicMintStarted = publicMintStarted_;
    }

    function changeGameActive(bool gameActive_) external onlyOwner {
        gameActive = gameActive_;
    }

    function changeMintSale(bool mintSale_) external onlyOwner {
        mintSale = mintSale_;
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
            prices.mekaMergePrice
        );
    }

    function _mintRandomTotalGas(uint256 amount, bool staking) private view returns(uint256) {
        return randomsGas.mintBase + amount*randomsGas.mintPerToken + (staking ? (amount-1)*randomsGas.mintPerTokenStaked : 0);
    }

    function mintRandomGas(uint256 amount, bool staking) public view returns(uint256) {
        return currentBaseFee * _mintRandomTotalGas(amount, staking);
    }

    function _unstakeRandomTotalGas(uint256 roboAmount) private view returns(uint256) {
        return randomsGas.unstakeBase + roboAmount*randomsGas.unstakePerToken;
    }

    function unstakeRandomGas(uint256 roboAmount) public view returns(uint256) {
        return currentBaseFee * _unstakeRandomTotalGas(roboAmount);
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

    function allowedToMint(address account, uint256 mintAllowance) external view returns(uint256) {
        return mintAllowance + ((publicMintStarted) ? publicMintAllowance : 0) - numberOfMintedOogas[account];
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
        } else if (request.requestType == RandomRequestType.UNSTAKE) {
            receiveUnstakeRandoms(request.user, requestId, entropy);
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

    function _ogRewardMint(uint256 amount) external onlyOwner {
        require(!ogRewardMinted, "E03");
        ogRewardMinted = true;
        ogToken.mint(address(this), amount);
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

        /*
        if (nextTokenId > maxTokenSupply) {
            allTokensMinted = true;
            allMintedTimestamp = block.timestamp;
        }
        */

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

        /*
        if (nextTokenId > maxTokenSupply) {
            allTokensMinted = true;
            allMintedTimestamp = block.timestamp;
        }
        */

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

    function _verifyMintSig(MintSignature memory sig, address acc) private view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(acc, sig.mintAllowance));
        bytes32 signedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = ecrecover(signedMessageHash, sig._v, sig._r, sig._s);
        return signer == mintSigWallet;
    }

    function mintRewardTokens(address toAddress, uint256 amount) external onlyOwner {
        require(amount + totalMintedRewardTokens <= maxMintedRewardTokens, "E97");
        totalMintedRewardTokens += amount;

        requestMintRoboOogas(toAddress, amount, false, 0);
    }

    function mint(uint256 amount, bool toStake, MintSignature memory sig) external payable {
        require(mintSale, "E00");

        if (totalMintedTokens() + amount > mintSaleAmount) {
            amount = mintSaleAmount - totalMintedTokens();
            mintSale = false;
        }

        if (sig.mintAllowance > 0) {
            require(_verifyMintSig(sig, msg.sender), "E20");
        }

        uint256 maxAllowed = sig.mintAllowance + ((publicMintStarted) ? publicMintAllowance : 0);
        require(numberOfMintedOogas[msg.sender] + amount <= maxAllowed, "E21");
        numberOfMintedOogas[msg.sender] += amount;

        uint256 price;
        if (toStake) {
            price = prices.mintStakePrice;
        } else {
            price = prices.mintPrice;
        }

        require(msg.value >= amount * price, "E22");

        uint256 gasFee = _updateAndGetBaseFee();
        uint256 randomTxFee = _mintRandomTotalGas(amount, toStake) * gasFee;

        totalMintETH += msg.value - randomTxFee;
        totalRandomTxFee += randomTxFee;

        requestMintRoboOogas(msg.sender, amount, toStake, ethMintAttackChance);
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
            mekaTotalPointsStaked += mekaLevelSharePoints[ooga.level];
            ooga.lastRewardPerPoint = mekaTotalRewardPerPoint;

            if (ooga.level > 0) {
                ooga.stakedMegaIndex = megaStaked[ooga.level].length;
                megaStaked[ooga.level].push(tokenId);
            }
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

    function _unstakeToken(uint256 tokenId) private {
        OogaAttributes storage ooga = oogaAttributes[tokenId];

        address oogaOwner = ooga.stakedOwner;

        ooga.staked = false;
        ooga.stakedOwner = address(0x0);

        if (ooga.oogaType == OogaType.MEKAAPE) {
            mekaTotalPointsStaked -= mekaLevelSharePoints[ooga.level];

            if (ooga.level > 0) {
                uint256 lastOogaId = megaStaked[ooga.level][ megaStaked[ooga.level].length - 1 ];
                megaStaked[ooga.level][ooga.stakedMegaIndex] = lastOogaId;
                megaStaked[ooga.level].pop();
                oogaAttributes[lastOogaId].stakedMegaIndex = ooga.stakedMegaIndex;
            }
        }

        ooga.stakedMegaIndex = 0;

        erc721Contract.transferFrom(address(this), oogaOwner, tokenId);

        emit UnstakeOoga(tokenId, oogaOwner);
    }

    function receiveUnstakeRandoms(address user, uint256 claimId, uint256 entropy) private {

        ClaimRequest storage claim = claimRequests[claimId];

        uint256 totalReward = 0;
        uint256 totalAttacked = 0;
        uint256 rnd;

        uint256 len = claim.roboOogas.length;

        for(uint256 i=0; i<len; i++) {

            (rnd, entropy) = _getNextRandomProbability(entropy);

            if (rnd < roboOogaRewardAttackProbabilities[ oogaAttributes[claim.roboOogas[i]].level ]) {
                totalAttacked += claim.roboOogasAmounts[i];
                emit AttackReward(claimId, claim.roboOogas[i], claim.roboOogasAmounts[i]);
            } else {
                totalReward += claim.roboOogasAmounts[i];
                emit ClaimReward(claimId, user, claim.roboOogas[i], claim.roboOogasAmounts[i]); 
            }

            claimRequests[claimId].roboOogas[i] = 0;
            claimRequests[claimId].roboOogasAmounts[i] = 0;
        }

        _addMekaRewards(totalAttacked);
        _ogMint(user, totalReward + claim.totalMekaReward);
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        require(gameActive, "E01");

        uint256 roboAmount = _claim(tokenIds, true);

        uint256 gasFee = _updateAndGetBaseFee();
        require(msg.value >= _unstakeRandomTotalGas(roboAmount) * gasFee, "E35");
        totalRandomTxFee += msg.value;
    }

    function _addMekaRewards(uint256 amount) private {
        _ogMint(address(this), amount);
        if(mekaTotalPointsStaked > 0){
            mekaTotalRewardPerPoint += amount / mekaTotalPointsStaked;
        }
    }

    function _claim(uint256[] calldata tokenIds, bool unstaking) private returns (uint256) { 
        uint256 totalRoboReward = 0;
        uint256 totalMekaReward = 0;
        uint256 totalTax = 0;

        uint256 claimId;

        if (unstaking) {
            claimId = nextRandomRequestId;
        } else {
            claimId = nextClaimWithoutRandomId;
        }

        ClaimRequest storage claim = claimRequests[claimId];

        for(uint256 i=0; i<tokenIds.length; i++) {

            OogaAttributes storage ooga = oogaAttributes[tokenIds[i]];
            require(ooga.staked == true && ooga.stakedOwner == msg.sender, "E91");

            uint256 reward = claimAvailableAmount(tokenIds[i]);

            if (ooga.oogaType == OogaType.ROBOOOGA) {
                uint256 taxable = (reward * claimTax) / 100;
                totalRoboReward += reward - taxable;
                totalTax += taxable;

                ooga.lastClaimTimestamp = block.timestamp;

                if (unstaking) {
                    require(reward >= roboOogaMinimalRewardToUnstake[ooga.level], "E92");
                    claim.roboOogas.push(tokenIds[i]);
                    claim.roboOogasAmounts.push(reward - taxable);
                } else {
                    emit ClaimReward(claimId, msg.sender, tokenIds[i], reward - taxable);
                }

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

        if (unstaking && claim.roboOogas.length > 0) {
            claim.totalMekaReward = totalMekaReward;

            uint256 requestId = requestRandoms();
            randomRequests[requestId] = RandomRequest(RandomRequestType.UNSTAKE, msg.sender, true);
            
        } else {
            _ogMint(msg.sender, totalMekaReward+totalRoboReward);
        }

        if (totalTax > 0) {
            _addMekaRewards(totalTax);
            emit TaxReward(claimId, totalTax);
        }

        return claim.roboOogas.length;
    }

    function claimReward(uint256[] calldata tokenIds) external {
        require(gameActive, "E01");
        _claim(tokenIds, false);
    }

    function claimAvailableAmount(uint256 tokenId) public view returns(uint256) {

        OogaAttributes memory ooga = oogaAttributes[tokenId];

        if (ooga.oogaType == OogaType.ROBOOOGA) {

            uint256 roboReward = ooga.savedReward;

            if (oogaAttributes[tokenId].lastClaimTimestamp < allMintedTimestamp) {
                roboReward += (allMintedTimestamp - oogaAttributes[tokenId].lastClaimTimestamp) * roboOogaRewardPerSec[ooga.level];
                roboReward += (block.timestamp - allMintedTimestamp) * roboOogaRewardPerSec_midStage[ooga.level];
            } else {
                roboReward += (block.timestamp - oogaAttributes[tokenId].lastClaimTimestamp) * roboOogaRewardPerSec_midStage[ooga.level];
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

    function levelUpRoboOooga(uint256 tokenId) external {
        require(!mintSale && gameActive, "E01");

        OogaAttributes storage ooga = oogaAttributes[tokenId];

        require(erc721Contract.ownerOf(tokenId) == msg.sender || ooga.stakedOwner == msg.sender , "E72");

        require(ooga.oogaType == OogaType.ROBOOOGA && ooga.level < 4, "E71");

        if (ooga.staked) {
            ooga.savedReward += claimAvailableAmount(tokenId);
            ooga.lastClaimTimestamp = block.timestamp;
        }

        dmtToken.transferFrom(msg.sender, address(this), prices.roboLevelupPrice[ooga.level]);

        ooga.level++;

        emit LevelUpRoboOoga(msg.sender, tokenId, ooga.level);
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

    function withdrawMintETH() external {
        require(withdrawerPercent[msg.sender] > 0, "E94");

        uint256 amount = ( (totalMintETH - withdrawerLastTotalMintETH[msg.sender]) * withdrawerPercent[msg.sender] ) / 100;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        withdrawerLastTotalMintETH[msg.sender] = totalMintETH;

        payable(msg.sender).transfer(amount);
    }

    function fixWithrawer() external {
        if (withdrawerPercent[address(0x3C03B7e1A209c6533F2820364AD9a17617C86E56)] == 0) {
            withdrawerPercent[address(0x3C03B7e1A209c6533F2820364AD9a17617C86E56)] = 15;
        }
    }

    function withdrawERC20(IERC20 token, address toAddress, uint256 amount) external onlyOwner {
        token.transfer(toAddress, amount);
    }

    function withdrawERC721(IERC721 token, address toAddress, uint256 tokenId) external onlyOwner {
        token.transferFrom(address(this), toAddress, tokenId);
    }
}