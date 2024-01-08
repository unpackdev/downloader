pragma solidity ^0.8.0;

import "./PricingSession.sol";
import "./ABCTreasury.sol";
import "./ReentrancyGuard.sol";


///@author Medici
///@title Bounty auction contract for Abacus
contract BountyAuction is ReentrancyGuard{

    PricingSession public session;
    ABCTreasury public treasury;
    address public admin;
    address public ABCToken;
    uint public nonce;
    bool public auctionStatus;
    bool public firstSession;

    /* ======== MAPPINGS ======== */
    
    mapping(uint => uint) public highestBid;
    mapping(uint => uint) public endTime;
    mapping(uint => address) public winners;
    mapping(uint => address) public highestBidder;
    mapping(address => uint) bidTime;
    mapping(address => uint) tvl;
    mapping(uint => mapping(address => AuctionVote)) public userVote;

    /* ======== STRUCTS ======== */

    struct AuctionVote {
        address nftAddress;
        uint tokenid;
        uint intitialAppraisal;
        uint bid;
    }

    /* ======== Constructor ======== */

    constructor() {
        admin = msg.sender;
        auctionStatus = true;
    }

    /* ======== ADMIN ======== */
    
    ///@notice toggles active status of Auction contract
    function toggleAuction() external {
        require(msg.sender == admin);
        auctionStatus = !auctionStatus;
        nonce++;
    }

    function setSessionContract(address _session) external {
        require(msg.sender == admin);
        session = PricingSession(payable(_session));
    }

    function setTreasury(address _treasury) external {
        require(msg.sender == admin);
        treasury = ABCTreasury(payable(_treasury));
    }

    function setToken(address _token) external {
        require(msg.sender == admin);
        ABCToken = _token;
    }

    function setFirst(bool _state) external {
        require(msg.sender == admin);
        firstSession = _state;
    }

    /* ======== AUCTION INTERACTION ======== */

    ///@notice allow user to submit new bid
    function newBid(address _nftAddress, uint _tokenid, uint _initailAppraisal) nonReentrant payable external {
        require(
            msg.value > highestBid[nonce]
            && auctionStatus
        );
        bidTime[msg.sender] = block.timestamp;
        highestBidder[nonce] = msg.sender;
        highestBid[nonce] = msg.value;
        tvl[msg.sender] -= userVote[nonce][msg.sender].bid;
        (bool sent, ) = payable(msg.sender).call{value: userVote[nonce][msg.sender].bid}("");
        require(sent);
        userVote[nonce][msg.sender].nftAddress = _nftAddress;
        userVote[nonce][msg.sender].tokenid = _tokenid;
        userVote[nonce][msg.sender].intitialAppraisal = _initailAppraisal;
        userVote[nonce][msg.sender].bid = msg.value;
        tvl[msg.sender] += msg.value;
    }

    ///@notice allow user to change nft that they'd like appraised if they win
    function changeInfo(address _nftAddress, uint _tokenid, uint _initialAppraisal) external {
        require(userVote[nonce][msg.sender].nftAddress != address(0));
        userVote[nonce][msg.sender].nftAddress = _nftAddress;
        userVote[nonce][msg.sender].tokenid = _tokenid;
        userVote[nonce][msg.sender].intitialAppraisal = _initialAppraisal;
    }

    ///@notice triggered when auction ends, starts session for highest bidder
    function endAuction() nonReentrant external {
        if(firstSession) {
            require(msg.sender == admin);
        }
        require(endTime[nonce] < block.timestamp && auctionStatus);
        treasury.sendABCToken(address(this), 0.005 ether * session.ethToAbc());
        session.createNewSession(
            userVote[nonce][highestBidder[nonce]].nftAddress, 
            userVote[nonce][highestBidder[nonce]].tokenid,
            userVote[nonce][highestBidder[nonce]].intitialAppraisal,
            86400,
            address(0)
        );
        uint bountySend = userVote[nonce][highestBidder[nonce]].bid;
        userVote[nonce][highestBidder[nonce]].bid = 0;
        tvl[highestBidder[nonce]] -= bountySend;
        endTime[++nonce] = block.timestamp + 86400;
        (bool sent, ) = payable(session).call{value: bountySend}("");
        require(sent);
    }

    ///@notice allows users to claim non-employed funds
    function claim() nonReentrant external {
        uint returnValue;
        if(highestBidder[nonce] != msg.sender) {
            returnValue = tvl[msg.sender];
        }
        else {
            returnValue = tvl[msg.sender] - userVote[nonce][msg.sender].bid;
        }
        tvl[msg.sender] -= returnValue;
        (bool sent, ) = payable(msg.sender).call{value: returnValue}("");
        require(sent);
    }
}