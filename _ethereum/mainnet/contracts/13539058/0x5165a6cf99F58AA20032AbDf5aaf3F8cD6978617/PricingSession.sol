pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./IABCTreasury.sol";
import "./SafeMath.sol";
import "./sqrtLibrary.sol";
import "./PostSessionLibrary.sol";
import "./IERC20.sol";

/// @author Medici
/// @title Pricing session contract for Abacus
contract PricingSession is ReentrancyGuard {

    using SafeMath for uint;

    address immutable public ABCToken;
    address immutable public Treasury;
    address auction;
    address admin;
    bool auctionStatus;
    
    /* ======== MAPPINGS ======== */

    mapping(address => mapping (uint => uint)) public nftNonce; 
    mapping(uint => mapping(address => mapping(uint => VotingSessionMapping))) NftSessionMap;
    mapping(uint => mapping(address => mapping(uint => VotingSessionChecks))) public NftSessionCheck;
    mapping(uint => mapping(address => mapping(uint => VotingSessionCore))) public NftSessionCore;
    mapping(uint => mapping(address => mapping(uint => uint))) public finalAppraisalValue;
    
    /* ======== STRUCTS ======== */

    struct VotingSessionMapping {
        mapping (address => uint) voterCheck;
        mapping (address => uint) winnerPoints;
        mapping (address => uint) amountHarvested;
        mapping (address => Voter) nftVotes;
    }

    struct VotingSessionChecks {
        uint sessionProgression;
        uint calls;
        uint correct;
        uint incorrect;
        uint timeFinalAppraisalSet;
    }

    struct VotingSessionCore {
        address Dao;

        uint endTime;
        uint lowestStake;
        uint maxAppraisal;
        uint totalAppraisalValue;
        uint totalSessionStake;
        uint totalProfit;
        uint totalWinnerPoints;
        uint totalVotes;
        uint uniqueVoters;
        uint votingTime;
    }

    struct Voter {
        bytes32 concealedBid;
        uint base;
        uint appraisal;
        uint stake;
    }

    /* ======== EVENTS ======== */

    event PricingSessionCreated(address DaoTokenContract, address creator_, address nftAddress_, uint tokenid_, uint initialAppraisal_, uint bounty_);
    event newAppraisalAdded(address voter_, uint stake_, uint appraisal, uint weight);
    event finalAppraisalDetermined(uint finalAppraisal, uint amountOfParticipants, uint totalStake);
    event lossHarvestedFromUser(address user_, uint harvested);
    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToPPExchange(address user_, uint ethExchanged, uint ppSent);
    event sessionEnded(address nftAddress, uint tokenid, uint nonce);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _ABCToken, address _treasury, address _auction) {
        ABCToken = _ABCToken;
        Treasury = _treasury;
        auction = _auction;
        admin = msg.sender;
        auctionStatus = true;
    }

    function setAuction(address _auction) external {
        require(msg.sender == admin);
        auction = _auction;
    }

    function setAuctionStatus(bool status) external {
        auctionStatus = status;
    }

    /// @notice Allow user to create new session and attach initial bounty
    /**
    @dev NFT sessions are indexed using a nonce per specific nft.
    The mapping is done by mapping a nonce to an NFT address to the 
    NFT token id. 
    */ 
    function createNewSession(
        address nftAddress,
        uint tokenid,
        uint _initialAppraisal,
        uint _votingTime,
        address _dao
    ) stopOverwrite(nftAddress, tokenid) external payable {
        require(_votingTime <= 1 days && (auctionStatus || msg.sender == auction));
        uint abcCost = 0.005 ether *(ethToAbc());
        (bool abcSent) = IERC20(ABCToken).transferFrom(msg.sender, Treasury, abcCost);
        require(abcSent);
        if(getStatus(nftAddress, tokenid) == 6) {
            _executeEnd(nftAddress, tokenid);
        }
        nftNonce[nftAddress][tokenid]++;
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCore.votingTime = _votingTime;
        sessionCore.maxAppraisal = 69420 * _initialAppraisal / 1000;
        sessionCore.lowestStake = 100000 ether;
        sessionCore.endTime = block.timestamp + _votingTime;
        sessionCore.totalSessionStake = msg.value;
        sessionCore.Dao = _dao;
        emit PricingSessionCreated(_dao, msg.sender, nftAddress, tokenid, _initialAppraisal, msg.value);
    }

    /* ======== USER VOTE FUNCTIONS ======== */
    
    /// @notice Allows user to set vote in party 
    /** 
    @dev Users appraisal is hashed so users can't track final appraisal and submit vote right before session ends.
    Therefore, users must remember their appraisal in order to reveal their appraisal in the next function.
    */
    function setVote(
        address nftAddress,
        uint tokenid,
        bytes32 concealedBid
    ) properVote(nftAddress, tokenid) payable external {
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[currentNonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[currentNonce][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp);
        // if(sessionCore.Dao != address(0)) {
        //     require(IERC20(sessionCore.Dao).balanceOf(msg.sender) > 0);
        // }
        sessionMap.voterCheck[msg.sender] = 1;
        if (msg.value < sessionCore.lowestStake) {
            sessionCore.lowestStake = msg.value;
        }
        sessionCore.uniqueVoters++;
        sessionCore.totalSessionStake = sessionCore.totalSessionStake.add(msg.value);
        sessionMap.nftVotes[msg.sender].concealedBid = concealedBid;
        sessionMap.nftVotes[msg.sender].stake = msg.value;
    }

    function updateVote(
        address nftAddress,
        uint tokenid,
        bytes32 concealedBid
    ) external {
        require(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] == 1);
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[currentNonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[currentNonce][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp);

        // if(sessionCore.Dao != address(0)) {
        //     require(IERC20(sessionCore.Dao).balanceOf(msg.sender) > 0);
        // }
        sessionCore.uniqueVoters++;
        sessionMap.nftVotes[msg.sender].concealedBid = concealedBid;
    }

    /// @notice Reveals user vote and weights based on the sessions lowest stake
    /**
    @dev calculation can be found in the weightVoteLibrary.sol file. 
    Votes are weighted as sqrt(userStake/lowestStake). Depending on a votes weight
    it is then added as multiple votes of that appraisal (i.e. if someoneone has
    voting weight of 8, 8 votes are submitted using their appraisal).
    */
    function weightVote(address nftAddress, uint tokenid, uint appraisal, uint seedNum) checkParticipation(nftAddress, tokenid) nonReentrant external {
        uint currentNonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[currentNonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[currentNonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(sessionCheck.sessionProgression < 2
                && sessionCore.endTime < block.timestamp
                && sessionMap.voterCheck[msg.sender] == 1
                && sessionMap.nftVotes[msg.sender].concealedBid == keccak256(abi.encodePacked(appraisal, msg.sender, seedNum))
                && sessionCore.maxAppraisal >= appraisal
        );
        sessionMap.voterCheck[msg.sender] = 2;
        if(sessionCheck.sessionProgression == 0) {
            sessionCheck.sessionProgression = 1;
        }
        sessionMap.nftVotes[msg.sender].appraisal = appraisal;
        uint weight = sqrtLibrary.sqrt(sessionMap.nftVotes[msg.sender].stake/sessionCore.lowestStake);
        sessionCore.totalVotes += weight;
        sessionCheck.calls++;
        
        sessionCore.totalAppraisalValue = sessionCore.totalAppraisalValue.add((weight) * sessionMap.nftVotes[msg.sender].appraisal);
        emit newAppraisalAdded(msg.sender, sessionMap.nftVotes[msg.sender].stake, sessionMap.nftVotes[msg.sender].appraisal, weight);
        if(sessionCheck.calls == sessionCore.uniqueVoters) {
            sessionCheck.sessionProgression = 2;
            sessionCheck.calls = 0;
        }
    }
    
    /// @notice takes average of appraisals and outputs a final appraisal value.
    function setFinalAppraisal(address nftAddress, uint tokenid) nonReentrant external {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(
            (block.timestamp > sessionCore.endTime + sessionCore.votingTime || sessionCheck.sessionProgression == 2)
        );

        if(sessionCheck.sessionProgression == 1) {
            sessionCheck.sessionProgression = 2;
        }
        IABCTreasury(Treasury).updateNftPriced();
        sessionCheck.calls = 0;
        sessionCheck.timeFinalAppraisalSet = block.timestamp;
        finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid] = (sessionCore.totalAppraisalValue)/(sessionCore.totalVotes);
        sessionCheck.sessionProgression = 3;
        emit finalAppraisalDetermined(finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], sessionCore.uniqueVoters, sessionCore.totalSessionStake);
    }

    /// @notice Calculates users base and harvests their loss before returning remaining stake
    /**
    @dev A couple notes:
    1. Base is calculated based on margin of error.
        > +/- 5% = 1
        > +/- 4% = 2
        > +/- 3% = 3
        > +/- 2% = 4
        > +/- 1% = 5
        > Exact = 6
    2. winnerPoints are calculated based on --> base * stake
    3. Losses are harvested based on --> (margin of error - 5%) * stake
    */
    function harvest(address nftAddress, uint tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(
            sessionCheck.sessionProgression == 3
        );
        sessionCheck.calls++;
        sessionMap.voterCheck[msg.sender] = 3;
        sessionMap.nftVotes[msg.sender].base = 
            PostSessionLibrary.calculateBase(
                finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], 
                sessionMap.nftVotes[msg.sender].appraisal
            );
        
        if(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].nftVotes[msg.sender].base > 0) {
            sessionCore.totalWinnerPoints += sessionMap.nftVotes[msg.sender].base * sessionMap.nftVotes[msg.sender].stake;
            sessionMap.winnerPoints[msg.sender] = sessionMap.nftVotes[msg.sender].base * sessionMap.nftVotes[msg.sender].stake;
            sessionCheck.correct++;
        }
        else {
            sessionCheck.incorrect++;
        }
        
       sessionMap.amountHarvested[msg.sender] = PostSessionLibrary.harvest( 
            sessionMap.nftVotes[msg.sender].stake, 
            sessionMap.nftVotes[msg.sender].appraisal,
            finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid]
        );

        sessionMap.nftVotes[msg.sender].stake -= sessionMap.amountHarvested[msg.sender];
        uint commission = PostSessionLibrary.setCommission(Treasury.balance).mul(sessionMap.amountHarvested[msg.sender]).div(10000);
        sessionCore.totalSessionStake -= commission;
        sessionMap.amountHarvested[msg.sender] -= commission;
        sessionCore.totalProfit += sessionMap.amountHarvested[msg.sender];
        IABCTreasury(Treasury).updateProfitGenerated(sessionMap.amountHarvested[msg.sender]);
        (bool sent, ) = payable(Treasury).call{value: commission}("");
        require(sent);
        emit lossHarvestedFromUser(msg.sender, sessionMap.amountHarvested[msg.sender]);

        if(sessionCheck.calls == sessionCore.uniqueVoters) {
            sessionCheck.sessionProgression = 4;
            sessionCheck.calls = 0;
        }
    }

    /// @notice User claims principal stake along with any earned profits in ETH or ABC form
    /**
    @dev 
    1. Calculates user principal return value
    2. Enacts sybil defense mechanism
    3. Edits totalProfits and totalSessionStake to reflect claim
    4. Checks trigger choice
    5. Executes desired payout of principal and profit
    */
    /// @param trigger trigger should be set to 1 if the user wants reward in ETH or 2 if user wants reward in ABC
    function claim(address nftAddress, uint tokenid, uint trigger) checkHarvestLoss(nftAddress, tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external returns(uint){
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require(block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime || sessionCheck.sessionProgression == 4);
        require(trigger == 1 || trigger == 2);
        uint principalReturn;
        sessionMap.voterCheck[msg.sender] = 4;
        if(sessionCheck.sessionProgression == 3) {
            sessionCheck.calls = 0;
            sessionCheck.sessionProgression = 4;
        }
        if(sessionCheck.correct * 100 / (sessionCheck.correct + sessionCheck.incorrect) >= 90) {
            principalReturn = sessionMap.nftVotes[msg.sender].stake + sessionMap.amountHarvested[msg.sender];
        }
        else {
            principalReturn = sessionMap.nftVotes[msg.sender].stake;
        }
        sessionCheck.calls++;
        uint payout = sessionCore.totalProfit * sessionMap.winnerPoints[msg.sender] / sessionCore.totalWinnerPoints;
        sessionCore.totalProfit -= payout;
        sessionCore.totalSessionStake -= payout + principalReturn;
        sessionCore.totalWinnerPoints -= sessionMap.winnerPoints[msg.sender];
        sessionMap.winnerPoints[msg.sender] = 0;
        if(sessionMap.winnerPoints[msg.sender] == 0) {
            trigger = 1;
        }
        if(trigger == 1) {
            (bool sent1, ) = payable(msg.sender).call{value: principalReturn + payout}("");
            require(sent1);
            emit ethClaimedByUser(msg.sender, payout);
        }
        else if(trigger == 2) {
            uint abcAmount = payout * 1e18 / (0.00005 ether + 0.000015 ether * IABCTreasury(Treasury).tokensClaimed() / 1000000);
            uint abcPayout = payout/2 * (1e18 / (0.00005 ether + 0.000015 ether * IABCTreasury(Treasury).tokensClaimed() / 1000000) + 1e18 / (0.00005 ether + 0.000015 ether * (IABCTreasury(Treasury).tokensClaimed() + abcAmount) / 1000000));
            (bool sent2, ) = payable(msg.sender).call{value: principalReturn}("");
            require(sent2);
            (bool sent3, ) = payable(Treasury).call{value: payout}("");
            require(sent3);
            IABCTreasury(Treasury).sendABCToken(msg.sender,abcPayout);
            emit ethToPPExchange(msg.sender, payout, abcPayout);
        }
        if(sessionCore.totalWinnerPoints == 0) {
            sessionCheck.sessionProgression = 5;
            _executeEnd(nftAddress, tokenid);
            return 0;
        }
        if(sessionCheck.calls == sessionCore.uniqueVoters || block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime*2) {
            sessionCheck.sessionProgression = 5;
            _executeEnd(nftAddress, tokenid);
            return 0;
        }

        return 1;
    }
    
    /// @notice Custodial function to clear funds and remove session as child
    /// @dev Caller receives 10% of the funds that are meant to be cleared
    function endSession(address nftAddress, uint tokenid) public {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        require((block.timestamp > sessionCheck.timeFinalAppraisalSet + sessionCore.votingTime * 2) || sessionCheck.sessionProgression == 5);
        _executeEnd(nftAddress, tokenid);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _executeEnd(address nftAddress, uint tokenid) internal {
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCheck.sessionProgression = 6;
        uint tPayout = 90*sessionCore.totalSessionStake/100;
        uint cPayout = sessionCore.totalSessionStake - tPayout;
        (bool sent, ) = payable(Treasury).call{value: tPayout}("");
        require(sent);
        (bool sent1, ) = payable(msg.sender).call{value: cPayout}("");
        require(sent1);
        sessionCore.totalSessionStake = 0;
        emit sessionEnded(nftAddress, tokenid, nftNonce[nftAddress][tokenid]);
    }

    /* ======== FUND INCREASE ======== */

    /// @notice allow any user to add additional bounty on session of their choice
    function addToBounty(address nftAddress, uint tokenid) payable external {
        require(NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime > block.timestamp);
        NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].totalSessionStake += msg.value;
    }
    
    /// @notice allow any user to support any user of their choice
    function addToAppraisal(address nftAddress, uint tokenid, address user) payable external {
        require(
            NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[user] == 1
            && NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime > block.timestamp
        );
        NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].nftVotes[user].stake += msg.value;
    }

    /* ======== VIEW FUNCTIONS ======== */

    function getStatus(address nftAddress, uint tokenid) view public returns(uint) {
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        return sessionCheck.sessionProgression;
    }

    function ethToAbc() view public returns(uint) {
        return 1e18 / (0.00005 ether + 0.000015 ether * IABCTreasury(Treasury).tokensClaimed() / 1000000);
    }

    function getEthPayout(address nftAddress, uint tokenid) view external returns(uint) {
        if(NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].totalWinnerPoints == 0) {
            return 0;
        }
        return NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].totalSessionStake * NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].winnerPoints[msg.sender] / NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].totalWinnerPoints;
    }

    function getVoterCheck(address nftAddress, uint tokenid, address _user) view external returns(uint) {
        return NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[_user];
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    modifier stopOverwrite(
        address nftAddress, 
        uint tokenid
    ) {
        require(
            nftNonce[nftAddress][tokenid] == 0 
            || getStatus(nftAddress, tokenid) == 6
        );
        _;
    }
    
    modifier properVote(
        address nftAddress,
        uint tokenid
    ) {
        require(
            NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] == 0
            && msg.value >= 0.005 ether
        );
        _;
    }
    
    modifier checkParticipation(
        address nftAddress,
        uint tokenid
    ) {
        require(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] > 0);
        _;
    }
    
    modifier checkHarvestLoss(
        address nftAddress,
        uint tokenid
    ) {
        require(
            NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].sessionProgression == 3
            || block.timestamp > (NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].timeFinalAppraisalSet + NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].votingTime)
        );
        _;
    }
}









