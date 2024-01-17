//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./RedBlackTreeLibrary.sol";

contract Coupon is ERC721Upgradeable, OwnableUpgradeable {
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;
  using RedBlackTreeLibrary for RedBlackTreeLibrary.Tree;

  struct CouponStruct {
    bytes32 teamName;
    bytes32 betsHome;
    bytes32 betsAway;
  }

  struct CouponInfo {
    uint256 id;
    bytes32 teamName;
    address teamNft;
    string teamNftName;
    bytes32 betsHome;
    bytes32 betsAway;
    uint256 teamMembers;
    bool hasSharedTweet;
  }

  struct Results {
    bytes32 resultsHome;
    bytes32 resultsAway;
  }

  struct IndividualCouponsRewards {
    uint8 rankingPosition;
    uint16 rewardsPoolPromile;
  }

  struct Game {
    bytes16 homeTeam;
    bytes16 awayTeam;
  }

  struct NftTeamInfo {
    bytes32 teamName;
    string nftName;
    address nftAddress;
    bool owned;
  }

  /* ============ Events ============ */
  event NewCoupon(uint256 indexed _couponId, bytes32 indexed _teamName, uint256 pricePaid);
  event NewTeamCreated(bytes32 indexed _teamName);
  event NewTeamReached10(bytes32 indexed _teamName);
  event CouponAddedToNewTeam(uint256 indexed _couponId, bytes32 indexed _teamName);

  uint256 public constant PRICE = 0.08 ether;
  uint256 public constant DISCOUNTED_PRICE = 0.06 ether;
  uint8 private constant MATCHES_AMOUNT = 64;
  uint8 private constant BITS_PER_NUMBER = 4;
  uint8 private constant MAX_NUMBER_OF_CLASSIFIED_TEAM_SCORES = 3; // top 3 team scores get paid
  uint8 private constant POOL_REWARDS_PERCENTAGE_FOR_INDIVIDUAL_COUPONS = 50;
  uint8 private constant POOL_REWARDS_PERCENTAGE_FOR_TEAM_COUPONS = 50;
  uint8 public maxNumberOfClassifiedCouponScores;
  uint8 private constant MINIMUM_TEAM_WALLETS_NUMBER = 10;
  uint256 private _totalRewardsAmountForIndividualCoupons;
  uint256 private _totalRewardsAmountForTeamCoupons;
  uint8 public maxWalletsInTeam;
  bytes32 private maxUint256;
  address private treasury;
  uint256 private minAmountOfEtherToStartTournament;
  // first stage: first match (1.) - index 0, last match (48.) - index 47
  // second stage: first match (49.) - index 48, last match (56.) - index 55
  uint8[] private startingMatchIndexOfStage;
  // 1st position 50%, 2nd 30%, 3rd 20%
  uint16[] private teamCouponsRewardsPromiles;

  // before the first game starts we're in stage 0, we can mint and update whole coupon
  // right after the first game starts we are in stage one, we can no longer mint, we can update coupons starting from playoffs 1/16
  // last betting stage is 4, there are 2 games for 1st and 3rd place
  // stage 5 starts after 1st or 3rd game begins, no bets are accepted, coupon can not be verified
  // stage 6 starts when all games have been played, individual coupon verification is active
  // stage 7 starts, individual verification is closed, team scores verification is active
  // the final stage is 8 - all games have been played, results have been uploaded, the betting tournament is closed, coupon verification is blocked
  // current stage means that we can bet on this stage
  uint8 public currentStage;

  Counters.Counter private counter;

  Results public results;
  Game[MATCHES_AMOUNT] public games;
  uint256 public prizePool;
  uint256 finalStageStartTimestamp;
  bool wasWhitelistUploaded;

  // couponId => coupon
  mapping(uint256 => CouponStruct) private coupons;
  // teamName => wallets in team
  mapping(bytes32 => EnumerableSet.AddressSet) private walletsInTeam;
  // wallet, teamName, index => coupon of wallet in team id
  mapping(address => mapping(bytes32 => uint256[])) public couponsOfWalletInTeam;
  // wallet, index => coupon of wallet id
  mapping(address => uint256[]) public couponsOfWallet;
  // team name => number of coupons
  mapping(bytes32 => uint256) public numberOfPaidCouponsInTeam;
  // team name => its nft address
  mapping(bytes32 => address) public teamsNft;
  // couponId => coupon score
  mapping(uint256 => uint16) public couponsScores;
  // score => ranking position
  mapping(uint16 => uint8) public scoreRankingPosition;
  // team score => ranking position
  mapping(uint64 => uint8) public teamScoreRankingPosition;
  // teamName, wallet => score
  mapping(bytes32 => mapping(address => uint16)) public bestScoreOfWalletInTeam;
  // teamName => team's score sum
  // max value == 100 wallets * (max coupon score = 320) = 32000
  mapping(bytes32 => uint16) public teamsScoreSum;
  // team score => number of teams with the same score
  mapping(uint64 => uint32) public numberOfTeamsWithScore;
  // teamName => was verified
  mapping(bytes32 => bool) public wasTeamVerified;
  // score => number of verified coupons with the same score
  mapping(uint256 => uint256) public numberOfVerifiedCouponsWithScore;
  // couponId => paid out or not paid out
  mapping(uint256 => bool) public paidOutIndividualCoupons;
  // user, team => paid out or not paid out
  mapping(address => mapping(bytes32 => bool)) public paidOutTeamReward;
  // user => number of remaining free coupons
  mapping(address => uint256) public whitelistedWallets;
  // couponId => was free coupon
  mapping(uint256 => bool) public whitelistedCoupons;
  // couponId => has shared twitter post upon minting
  mapping(uint256 => bool) public hasSharedUponMinting;

  // all nfts
  address[] nfts;
  // nft => active team
  mapping(address => bytes32) public activeTeam;

  RedBlackTreeLibrary.Tree bestScoresTree;
  RedBlackTreeLibrary.Tree bestTeamScoresTree;

  IndividualCouponsRewards[] public _individualCouponsRewardsStructure;

  function initialize(
    uint8 _maxWalletsInTeam,
    IndividualCouponsRewards[] memory individualCouponsRewardsStructure,
    address _treasury,
    uint256 _minAmountOfEtherToStartTournament
  ) public initializer {
    __Ownable_init();
    __ERC721_init('WGMI2022', 'WGMI2022');
    maxWalletsInTeam = _maxWalletsInTeam;
    treasury = _treasury;
    minAmountOfEtherToStartTournament = _minAmountOfEtherToStartTournament;
    unchecked {
      maxUint256 = bytes32(uint256(0) - 1);
    }
    currentStage = 0;
    startingMatchIndexOfStage = [0, 48, 56, 60, 62];
    teamCouponsRewardsPromiles = [500, 300, 200];

    uint8 rewardsLength = uint8(individualCouponsRewardsStructure.length);
    for (uint8 i = 0; i < rewardsLength; ++i) {
      _individualCouponsRewardsStructure.push(individualCouponsRewardsStructure[i]);
    }

    // last element in individual rewards structure determines maxNumberOfClassifiedCouponScores
    maxNumberOfClassifiedCouponScores = individualCouponsRewardsStructure[rewardsLength - 1].rankingPosition;
  }

  function mintCoupon(
    bytes32 betsHome,
    bytes32 betsAway,
    bytes32 teamName,
    address teamNftAddress,
    bool hasShared
  ) external payable returns (uint256) {
    require(currentStage == 0, 'Matches already started');
    if (!isBytesEmpty(teamName)) {
      require(teamNftAddress == address(0), 'Nft address you provided will be ignored');
      require(teamsNft[teamName] == address(0), 'This team can be joined only by nft');
      require(
        walletsInTeam[teamName].length() < maxWalletsInTeam || walletsInTeam[teamName].contains(msg.sender),
        'Team is full'
      );
    }
    bool whitelistedCoupon = isEligibleForWhitelistedCoupon(msg.sender);
    uint256 discountedPriceDiff = willNextCouponBeEligibleForDiscountedPrice(teamName, teamNftAddress, msg.sender)
      ? PRICE - DISCOUNTED_PRICE
      : 0;
    uint256 requiredEth = whitelistedCoupon ? 0 : PRICE - discountedPriceDiff;

    // Removing coupon early in order to prevent reentrancy on balanceOf call
    if (whitelistedCoupon) {
      whitelistedWallets[msg.sender] -= 1;
    }

    require(msg.value == requiredEth, 'Wrong amount of ethers sent');

    if (teamNftAddress != address(0)) {
      require(IERC721(teamNftAddress).balanceOf(msg.sender) > 0, 'You do not own this nft');
      // first time we meet this nft
      if (isBytesEmpty(activeTeam[teamNftAddress])) {
        nfts.push(teamNftAddress);
        teamName = keccak256(abi.encode(block.number, teamNftAddress));
        activeTeam[teamNftAddress] = teamName;
        teamsNft[teamName] = teamNftAddress;
      }
      // another time
      else {
        teamName = activeTeam[teamNftAddress];
        // team is full
        if (walletsInTeam[teamName].length() == maxWalletsInTeam && !walletsInTeam[teamName].contains(msg.sender)) {
          // create new team
          teamName = keccak256(abi.encode(block.number, teamNftAddress));
          activeTeam[teamNftAddress] = teamName;
          teamsNft[teamName] = teamNftAddress;
        }
      }
    }

    uint256 couponId = counter.current();
    _safeMint(msg.sender, couponId);
    counter.increment();

    // Free coupons do not provide any value into prize pool
    if (!whitelistedCoupon) {
      prizePool += ((PRICE - discountedPriceDiff) * 8) / 10;
    } else {
      whitelistedCoupons[couponId] = true;
    }

    if (hasShared) {
      hasSharedUponMinting[couponId] = true;
    }

    if (!isBytesEmpty(teamName)) {
      if (
        walletsInTeam[teamName].length() == MINIMUM_TEAM_WALLETS_NUMBER - 1 &&
        !walletsInTeam[teamName].contains(msg.sender)
      ) {
        // Remove cashbacks from current prize pool
        prizePool -= ((discountedPriceDiff) * (numberOfPaidCouponsInTeam[teamName]) * 8) / 10;

        emit NewTeamReached10(teamName);
      }

      if (walletsInTeam[teamName].length() == 0) {
        emit NewTeamCreated(teamName);
      }

      walletsInTeam[teamName].add(msg.sender);
      couponsOfWalletInTeam[msg.sender][teamName].push(couponId);

      // Free coupons do not count as paid coupons
      if (!whitelistedCoupon) {
        numberOfPaidCouponsInTeam[teamName] += 1;
      }
    }

    couponsOfWallet[msg.sender].push(couponId);

    coupons[couponId].teamName = teamName; // can be empty here => can create team later on then
    coupons[couponId].betsHome = betsHome;
    coupons[couponId].betsAway = betsAway;

    emit NewCoupon(couponId, teamName, msg.value);

    return couponId;
  }

  function getAvailableNftTeamsFor(address user) external view returns (NftTeamInfo[] memory) {
    NftTeamInfo[] memory availableNftTeamInfos = new NftTeamInfo[](nfts.length);
    for (uint256 i = 0; i < nfts.length; i++) {
      availableNftTeamInfos[i] = NftTeamInfo(
        activeTeam[nfts[i]],
        ERC721(nfts[i]).name(),
        nfts[i],
        IERC721(nfts[i]).balanceOf(user) > 0
      );
    }
    return availableNftTeamInfos;
  }

  function createTeamAndAddToCoupon(bytes32 teamName, uint256 couponId) external {
    require(ownerOf(couponId) == msg.sender, 'You do not own that coupon');
    require(!isBytesEmpty(teamName), "Team name can't be empty");
    require(isBytesEmpty(coupons[couponId].teamName), 'This coupon already belongs to a team');
    require(teamName.length <= 32, 'Team name can have max 32 characters');
    require(walletsInTeam[teamName].length() == 0, 'Team name taken');
    require(teamsNft[teamName] == address(0), 'This team can be joined only by nft');
    walletsInTeam[teamName].add(msg.sender);
    couponsOfWalletInTeam[msg.sender][teamName].push(couponId);

    // Do not include free coupons into paid coupons count
    if (!whitelistedCoupons[couponId]) {
      numberOfPaidCouponsInTeam[teamName] += 1;
    }

    coupons[couponId].teamName = teamName;

    emit NewTeamCreated(teamName);
    emit CouponAddedToNewTeam(couponId, teamName);
  }

  // update coupon bets of next stages
  function updateCoupon(
    uint256 couponId,
    bytes32 newBetsHome,
    bytes32 newBetsAway
  ) external {
    require(ownerOf(couponId) == msg.sender, 'You do not own that coupon');
    require(!isBettingClosed(), 'Betting is closed');

    uint8 startingMatchIndexOfCurrentStage = startingMatchIndexOfStage[currentStage];
    uint8 numberOfMatchesToUpdate = MATCHES_AMOUNT - startingMatchIndexOfCurrentStage;

    coupons[couponId].betsHome = getUpdatedBets(coupons[couponId].betsHome, newBetsHome, numberOfMatchesToUpdate);
    coupons[couponId].betsAway = getUpdatedBets(coupons[couponId].betsAway, newBetsAway, numberOfMatchesToUpdate);
  }

  function verifyCoupons(uint256[] calldata couponIds) external {
    require(isTournamentClosedAndIndividualVerificationOpen(), 'Tournament is still active');
    for (uint8 i = 0; i < couponIds.length; i++) {
      uint256 couponId = couponIds[i];
      CouponStruct storage coupon = coupons[couponId];
      uint16 score;
      if (hasSharedUponMinting[couponId]) {
        score += 1;
      }
      for (uint8 j = 0; j < 64; j++) {
        uint8 couponBetHome = extractGameResult(j, coupon.betsHome);
        uint8 couponBetAway = extractGameResult(j, coupon.betsAway);
        uint8 resultHome = extractGameResult(j, results.resultsHome);
        uint8 resultAway = extractGameResult(j, results.resultsAway);
        if (couponBetHome == resultHome && couponBetAway == resultAway) {
          score += 5;
        } else if (couponBetHome == couponBetAway && resultHome == resultAway) {
          score += 2;
        } else if (couponBetHome < couponBetAway && resultHome < resultAway) {
          score += 2;
        } else if (couponBetHome > couponBetAway && resultHome > resultAway) {
          score += 2;
        }
      }
      // score 0 is not entitled for rewards because it's not added to tree
      if (couponsScores[couponId] == 0) {
        numberOfVerifiedCouponsWithScore[score] += 1;
      }
      couponsScores[couponId] = score;
      if (!RedBlackTreeLibrary.isEmpty(score) && !bestScoresTree.exists(score)) {
        bestScoresTree.insert(score);
      }
      if (!isBytesEmpty(coupon.teamName) && score > bestScoreOfWalletInTeam[coupon.teamName][ownerOf(couponId)]) {
        uint16 scoreDiff = score - bestScoreOfWalletInTeam[coupon.teamName][ownerOf(couponId)];
        bestScoreOfWalletInTeam[coupon.teamName][ownerOf(couponId)] = score;
        teamsScoreSum[coupon.teamName] += scoreDiff;
      }
    }
  }

  function verifyTeam(bytes32 teamName) external {
    require(!isBytesEmpty(teamName), "Team name can't be empty");
    require(walletsInTeam[teamName].length() >= MINIMUM_TEAM_WALLETS_NUMBER, 'Team does not qualify for rewards');
    require(isIndividualVerificationClosed(), 'Individual coupon verification is not closed');
    require(!isTeamVerificationClosed(), 'Team verification is closed');
    require(!wasTeamVerified[teamName], 'This team was already verified');
    uint64 teamScore = getTeamScore_d6(teamName);
    if (!RedBlackTreeLibrary.isEmpty(teamScore) && !bestTeamScoresTree.exists(teamScore)) {
      bestTeamScoresTree.insert(teamScore);
    }
    numberOfTeamsWithScore[teamScore] += 1;
    wasTeamVerified[teamName] = true;
  }

  // upload games in chronological order before next stage starts, preferably right after last match of the current stage
  function uploadGames(Game[] memory gamesArg) external onlyOwner {
    require(!isBettingClosed(), 'No games left to upload');
    uint256 numberOfMatchesInNextStage = getNumberOfMatchesInNextStage();
    require(gamesArg.length == numberOfMatchesInNextStage, 'Wrong number of matches provided');
    for (uint8 i = 0; i < numberOfMatchesInNextStage; i++) {
      games[startingMatchIndexOfStage[currentStage] + i] = gamesArg[i];
    }
  }

  // call before first match of the stage
  // you can't close the game with this function
  function setNextBettingStage() external onlyOwner {
    require(!isBettingClosed(), 'Last betting stage reached');
    require(
      games[startingMatchIndexOfStage[currentStage]].homeTeam != '',
      'Please upload games before setting next stage'
    );
    currentStage = currentStage + 1;
    if (currentStage == 1) {
      // minting just closed
      // transfer everything except for prize pool
      uint256 amount = address(this).balance - prizePool;
      payable(treasury).transfer(amount);
    }
  }

  function closeTournament(bytes32 home, bytes32 away) external onlyOwner {
    require(currentStage == 5, 'Last betting stage not reached');
    results.resultsHome = home;
    results.resultsAway = away;
    currentStage = 6;
  }

  function closeIndividualVerificationStage() external onlyOwner {
    require(isTournamentClosedAndIndividualVerificationOpen(), 'Tournament is not closed');
    _fetchRankingFromBestScoresTree();
    _totalRewardsAmountForIndividualCoupons = (prizePool * POOL_REWARDS_PERCENTAGE_FOR_INDIVIDUAL_COUPONS) / 100;
    currentStage = 7;
  }

  function closeTeamVerificationStage() external onlyOwner {
    require(isIndividualVerificationClosed(), 'Individual coupon verification is not closed');
    require(!isTeamVerificationClosed(), 'Team verification is closed');
    _fetchRankingFromBestTeamScoresTree();
    _totalRewardsAmountForTeamCoupons = (prizePool * POOL_REWARDS_PERCENTAGE_FOR_TEAM_COUPONS) / 100;
    currentStage = 8;
    finalStageStartTimestamp = block.timestamp;
  }

  function uploadWhitelist(address[] calldata _whitelist) external onlyOwner {
    require(!wasWhitelistUploaded, 'Whitelist already uploaded');

    // Treat empty whitelist as non valid one
    if (_whitelist.length > 0) {
      wasWhitelistUploaded = true;
    }

    uint256 rewardsLength = uint256(_whitelist.length);
    for (uint256 i = 0; i < rewardsLength; ++i) {
      whitelistedWallets[_whitelist[i]] += 1;
    }
  }

  function getTeamScore_d6(bytes32 teamName) public view returns (uint64) {
    return (1e6 * uint64(teamsScoreSum[teamName])) / uint16(walletsInTeam[teamName].length());
  }

  function isTournamentClosedAndIndividualVerificationOpen() public view returns (bool) {
    return currentStage == 6;
  }

  function isIndividualVerificationClosed() public view returns (bool) {
    return currentStage >= 7;
  }

  function isTeamVerificationClosed() public view returns (bool) {
    return currentStage >= 8;
  }

  function isBettingClosed() public view returns (bool) {
    return currentStage > 4;
  }

  function getNumberOfMatchesInNextStage() private view returns (uint8) {
    if (currentStage == 4) {
      return MATCHES_AMOUNT - startingMatchIndexOfStage[currentStage];
    } else if (currentStage < 4) {
      return startingMatchIndexOfStage[currentStage + 1] - startingMatchIndexOfStage[currentStage];
    } else {
      return 0;
    }
  }

  function getCoupon(uint256 couponId) external view returns (CouponStruct memory) {
    return coupons[couponId];
  }

  function getWalletsInTeam(bytes32 teamName) external view returns (address[] memory) {
    return walletsInTeam[teamName].values();
  }

  function isTeamNameTaken(bytes32 teamName) external view returns (bool) {
    return walletsInTeam[teamName].length() != 0;
  }

  function walletsInTeamExcludingWallet(bytes32 teamName, address wallet) external view returns (uint256) {
    return walletsInTeam[teamName].length() - (walletsInTeam[teamName].contains(wallet) ? 1 : 0);
  }

  function isBytesEmpty(bytes32 theBytes) private pure returns (bool) {
    return theBytes == bytes32(0);
  }

  function isEligibleForWhitelistedCoupon(address wallet) private view returns (bool) {
    return whitelistedWallets[wallet] > 0;
  }

  function willNextCouponBeEligibleForDiscountedPrice(
    bytes32 teamName,
    address teamNftAddress,
    address wallet
  ) public view returns (bool) {
    if (!isBytesEmpty(activeTeam[teamNftAddress])) {
      teamName = activeTeam[teamNftAddress];
    }

    if (isBytesEmpty(teamName)) {
      return false;
    }

    bool isNewWallet = !walletsInTeam[teamName].contains(wallet);

    if (isNewWallet && teamNftAddress != address(0) && walletsInTeam[teamName].length() == maxWalletsInTeam) {
      // new rolling NFT team
      return false;
    }

    uint256 walletsThreshold = isNewWallet ? MINIMUM_TEAM_WALLETS_NUMBER - 1 : MINIMUM_TEAM_WALLETS_NUMBER;
    return walletsInTeam[teamName].length() >= walletsThreshold;
  }

  function getUpdatedBets(
    bytes32 oldBets,
    bytes32 newBets,
    uint8 numberOfMatchesToUpdate
  ) private view returns (bytes32) {
    bytes32 oldBetsMask = maxUint256 << (uint256(numberOfMatchesToUpdate) * BITS_PER_NUMBER);
    bytes32 newBetsMask = oldBetsMask ^ maxUint256; // negation
    bytes32 updatedBets = (oldBets & oldBetsMask) | (newBets & newBetsMask);
    return updatedBets;
  }

  function extractGameResult(uint8 gameIndex, bytes32 bets) public pure returns (uint8) {
    uint8 goals = uint8((uint256(bets) << (gameIndex * BITS_PER_NUMBER)) >> (63 * BITS_PER_NUMBER));
    return goals;
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable) {
    revert('Coupons transfers not allowed');
  }

  function getAllCouponsOf(address owner) external view returns (CouponInfo[] memory) {
    uint256[] memory ids = couponsOfWallet[owner];
    CouponInfo[] memory couponInfos = new CouponInfo[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      CouponStruct memory cStruct = coupons[ids[i]];
      uint256 teamMembers = walletsInTeam[cStruct.teamName].length();
      address nftAddress = teamsNft[cStruct.teamName];
      string memory nftName;
      if (nftAddress != address(0)) {
        nftName = ERC721(nftAddress).name();
      }

      couponInfos[i] = CouponInfo(
        ids[i],
        cStruct.teamName,
        nftAddress,
        nftName,
        cStruct.betsHome,
        cStruct.betsAway,
        teamMembers,
        hasSharedUponMinting[ids[i]]
      );
    }
    return couponInfos;
  }

  function getAllGames() external view returns (Game[] memory) {
    Game[] memory gameList = new Game[](games.length);
    for (uint256 i = 0; i < games.length; i++) {
      gameList[i] = games[i];
    }
    return gameList;
  }

  function _fetchRankingFromBestScoresTree() private {
    uint16 score = uint16(bestScoresTree.last());
    scoreRankingPosition[score] = 1;

    for (uint8 rankingPosition = 2; rankingPosition <= maxNumberOfClassifiedCouponScores; ++rankingPosition) {
      score = uint16(bestScoresTree.prev(score));
      if (RedBlackTreeLibrary.isEmpty(score)) {
        break;
      }
      scoreRankingPosition[score] = rankingPosition;
    }
  }

  function _fetchRankingFromBestTeamScoresTree() private {
    uint64 teamScore = uint64(bestTeamScoresTree.last());
    teamScoreRankingPosition[teamScore] = 1;

    for (uint8 rankingPosition = 2; rankingPosition <= MAX_NUMBER_OF_CLASSIFIED_TEAM_SCORES; ++rankingPosition) {
      teamScore = uint64(bestTeamScoresTree.prev(teamScore));
      if (RedBlackTreeLibrary.isEmpty(teamScore)) {
        break;
      }
      teamScoreRankingPosition[teamScore] = rankingPosition;
    }
  }

  function getIndividualCouponRewardPoolPromileForRankingPosition(uint8 rankingPosition) public view returns (uint256) {
    for (uint8 i = 0; i < _individualCouponsRewardsStructure.length; ++i) {
      if (rankingPosition <= _individualCouponsRewardsStructure[i].rankingPosition) {
        return uint256(_individualCouponsRewardsStructure[i].rewardsPoolPromile);
      }
    }
    return 0;
  }

  function claimIndividualCouponReward(uint256 couponId) public {
    require(isIndividualVerificationClosed(), 'Coupons verification still open');
    require(!paidOutIndividualCoupons[couponId], 'This coupon received its reward');
    require(ownerOf(couponId) == msg.sender, 'Only coupon owner can claim rewards');

    uint16 score = couponsScores[couponId];
    uint8 rankingPosition = scoreRankingPosition[score];

    require(rankingPosition != 0, 'Coupon is not winning');

    uint256 rewardAmount = (_totalRewardsAmountForIndividualCoupons *
      getIndividualCouponRewardPoolPromileForRankingPosition(rankingPosition)) /
      (1_000 * numberOfVerifiedCouponsWithScore[score]);
    paidOutIndividualCoupons[couponId] = true;
    payable(msg.sender).transfer(rewardAmount);
  }

  function claimCouponsRewards(uint256[] calldata couponIds) public {
    for (uint256 i = 0; i < couponIds.length; ++i) {
      claimIndividualCouponReward(couponIds[i]);
    }
  }

  function claimTeamReward(bytes32 teamName) public {
    require(walletsInTeam[teamName].contains(msg.sender), "You're not in this team");
    require(isTeamVerificationClosed(), 'Coupons verification still open');
    require(!paidOutTeamReward[msg.sender][teamName], 'This user received its reward');

    uint64 teamScore = getTeamScore_d6(teamName);
    uint8 rankingPosition = teamScoreRankingPosition[teamScore];

    require(rankingPosition >= 1 && rankingPosition <= 3, 'Team is not winning');

    uint256 rewardAmount = (_totalRewardsAmountForTeamCoupons * teamCouponsRewardsPromiles[rankingPosition - 1]) /
      (1_000 * numberOfTeamsWithScore[teamScore]) /
      walletsInTeam[teamName].length();
    paidOutTeamReward[msg.sender][teamName] = true;
    payable(msg.sender).transfer(rewardAmount);
  }

  // can be used 60 days after final stage reached
  function withdrawAll() external onlyOwner {
    require(isTeamVerificationClosed(), 'Final stage not reached'); // final stage timestamp not yet set
    require(block.timestamp > finalStageStartTimestamp + 60 days, 'Too early to withdraw all');

    payable(msg.sender).transfer(address(this).balance);
  }

  // refund
  function releaseFundsToTreasury() external onlyOwner {
    require(currentStage > 0, 'Minting still active');
    require(prizePool < minAmountOfEtherToStartTournament, 'Prize pool too big to refund');

    payable(treasury).transfer(address(this).balance);
  }
}
