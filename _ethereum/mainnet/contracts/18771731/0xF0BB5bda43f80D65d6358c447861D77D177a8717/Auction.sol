// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.22;

import "./Strings.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Interfaces.sol";

/*
*  _____                  _         ___  ___                           _          ___             _   _             
* /  __ \                | |        |  \/  |                          | |        / _ \           | | (_)            
* | /  \/_ __ _   _ _ __ | |_ ___   | .  . | ___  _ __ ___   ___ _ __ | |_ ___  / /_\ \_   _  ___| |_ _  ___  _ __  
* | |   | '__| | | | '_ \| __/ _ \  | |\/| |/ _ \| '_ ` _ \ / _ \ '_ \| __/ __| |  _  | | | |/ __| __| |/ _ \| '_ \ 
* | \__/\ |  | |_| | |_) | || (_) | | |  | | (_) | | | | | |  __/ | | | |_\__ \ | | | | |_| | (__| |_| | (_) | | | |
*  \____/_|   \__, | .__/ \__\___/  \_|  |_/\___/|_| |_| |_|\___|_| |_|\__|___/ \_| |_/\__,_|\___|\__|_|\___/|_| |_|
*              __/ | |                                                                                              
*             |___/|_|                                                                                              
*/

/**
 * @title Auction
 * @notice CryptoMoments auction contract
 * @notice This contract is heavily inspired by Heedong BlindAuction, which in turn was heavily inspired by Kubz and Captainz contracts.
 * @author @apetech_
 */

contract Auction is Initializable, OwnableUpgradeable {
    IWoodFrame public woodContract;

    enum AuctionState {
        NOT_STARTED,
        BIDDING_STARTED,
        BIDDING_ENDED,
        REFUND_ENDED
    }

    AuctionState public auctionState;

    address public financeWalletAddress;

    uint256 public biddingEndTime;

    uint256 public minBidAmount;

    uint256 public bidId;

    address[] public bidders;

    uint256 public totalBids;

    struct Bid {
        bool exists;
        address bidder;
        uint32 createdAt;
        uint32 updatedAt;
        uint256 amount;
    }

    struct IndividualBid {
        address bidder;
        uint32 createdAt;
        uint256 amount;
    }

    struct UserStatus {
        bool isRefunded;
        bool isAirdropped;
    }

    mapping(address => Bid) private userBids; // address => bid
    mapping(address => UserStatus) private userStatus;
    mapping(uint256 => IndividualBid) public individualBids; // uint256 => individual bids with a unique identifier

    modifier auctionMustNotHaveStarted() {
        require(
            auctionState == AuctionState.NOT_STARTED,
            "Auction already started"
        );
        _;
    }

    event BidCommited(address indexed user, uint256 amount);

    event UserRefunded(address indexed user, uint256 indexed amount);

    event UserAirdopped(address indexed user, uint256 indexed quantity);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address financeWallet) public initializer {
        OwnableUpgradeable.__Ownable_init(msg.sender);
        setFinanceWalletAddress(financeWallet);
        minBidAmount = 0.1 ether;
    }

    function setCryptoMoments(address _address) public onlyOwner {
        woodContract = IWoodFrame(_address);
    }

    function commitBid() external payable {
        require(
            auctionState == AuctionState.BIDDING_STARTED,
            "auction is not started yet"
        );
        require(block.timestamp < biddingEndTime, "auction has ended");
        require(msg.value != 0, "Bid must be > 0");
        uint256 newAmount = userBids[msg.sender].amount + msg.value;
        require(newAmount >= minBidAmount, "Min Bid Required");

        individualBids[bidId] = IndividualBid({
            bidder: msg.sender,
            amount: msg.value,
            createdAt: uint32(block.timestamp)
        });

        unchecked {
            ++bidId;
        }

        emit BidCommited(msg.sender, msg.value);

        if (userBids[msg.sender].exists) {
            userBids[msg.sender].amount = newAmount;
            userBids[msg.sender].updatedAt = uint32(block.timestamp);
        } else {
            userBids[msg.sender] = Bid({
                exists: true,
                bidder: msg.sender,
                amount: newAmount,
                createdAt: uint32(block.timestamp),
                updatedAt: uint32(block.timestamp)
            });
            bidders.push(msg.sender);
        }
        totalBids += msg.value;
    }

    /// @dev returns a list of bids on everytime a bid commited individually
    /// this function should never be called on-chain
    function getIndividualBids()
        external
        view
        returns (IndividualBid[] memory)
    {
        IndividualBid[] memory _individualBids = new IndividualBid[](bidId);
        for (uint256 i = 0; i < bidId; i++) {
            _individualBids[i] = individualBids[i];
        }
        return _individualBids;
    }

    /// @dev returns a list of bidders and their total bid amounts
    /// this function should never be called on-chain
    function getBids() external view returns (Bid[] memory) {
        Bid[] memory _bids = new Bid[](bidders.length);
        for (uint256 i; i < bidders.length; i++) {
            _bids[i] = userBids[bidders[i]];
        }
        return _bids;
    }

    /// @dev gets the user's bid
    /// @return bidAmount the user's bid amount
    function getUserBid(
        address _address
    ) external view returns (uint256 bidAmount) {
        return userBids[_address].amount;
    }

    function getBiddersLength() external view returns (uint256) {
        return bidders.length;
    }

    function getBiddersAll() external view returns (address[] memory) {
        return bidders;
    }

    function refund(
        address[] calldata _bidders,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            auctionState == AuctionState.BIDDING_ENDED,
            "Bidding not ended yet"
        );

        for (uint256 i = 0; i < _bidders.length; i++) {
            address bidder = _bidders[i];
            require(!userStatus[bidder].isRefunded, "Already refunded");
            userStatus[bidder].isRefunded = true;
            emit UserRefunded(bidder, amounts[i]);
            _withdraw(bidder, amounts[i]);
        }
    }

    function airdrop(
        address[] calldata _bidders,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(auctionState == AuctionState.REFUND_ENDED, "Refund not ended");

        for (uint256 i = 0; i < _bidders.length; i++) {
            address bidder = _bidders[i];
            require(!userStatus[bidder].isAirdropped, "Already airdropped");
            userStatus[bidder].isAirdropped = true;
            emit UserAirdopped(bidder, quantities[i]);
            woodContract.mint(bidder, quantities[i]);
        }
    }

    /// @dev withdraw all proceeds to the finance wallet
    function withdrawAll() external onlyOwner {
        require(
            auctionState >= AuctionState.REFUND_ENDED,
            "Auction refund not ended"
        );
        _withdraw(financeWalletAddress, address(this).balance);
    }

    /// @dev withdraws a fixed amount to the given address
    /// @param _address address to withdraw to
    /// @param _amount amount to withdraw
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    /// @dev sets the finance wallet address
    /// @param _financeWalletAddress finance wallet address
    function setFinanceWalletAddress(
        address _financeWalletAddress
    ) public onlyOwner {
        require(_financeWalletAddress != address(0), "Invalid address");
        financeWalletAddress = _financeWalletAddress;
    }

    //  ============================================================
    //  Auction Administration
    //  ============================================================

    function changeMinBidAmount(
        uint256 amount
    ) external auctionMustNotHaveStarted onlyOwner {
        minBidAmount = amount;
    }

    /// @dev sets the countdown from bidding started to bidding ended
    function startAuction() external onlyOwner {
        require(
            auctionState != AuctionState.BIDDING_STARTED,
            "Auction is already started"
        );
        auctionState = AuctionState.BIDDING_STARTED;
        biddingEndTime = block.timestamp + 24 hours;
    }

    function setAuctionState(uint8 state) external onlyOwner {
        auctionState = AuctionState(state);
    }

    ///@dev this function should never be called on-chain
    function getRefundStatus()
        external
        view
        returns (address[] memory, bool[] memory)
    {
        address[] storage _bidders = bidders;
        bool[] memory _isUserRefunded = new bool[](_bidders.length);
        for (uint256 i; i < _bidders.length; i++) {
            _isUserRefunded[i] = userStatus[_bidders[i]].isRefunded;
        }

        return (_bidders, _isUserRefunded);
    }

    ///@dev this function should never be called on-chain
    function getAirdropStatus()
        external
        view
        returns (address[] memory, bool[] memory)
    {
        address[] storage _bidders = bidders;
        bool[] memory _isUserAirdropped = new bool[](_bidders.length);
        for (uint256 i; i < _bidders.length; i++) {
            _isUserAirdropped[i] = userStatus[_bidders[i]].isAirdropped;
        }

        return (_bidders, _isUserAirdropped);
    }
}