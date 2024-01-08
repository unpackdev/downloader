//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721HolderUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ISouly.sol";

contract SoulyAuction is ERC721HolderUpgradeable, AccessControlUpgradeable {

    using SafeMathUpgradeable for uint256;

    uint8 private constant COMMISSION_EXPONENT = 4;

    uint256 private _platformCommissionPercent;
    address payable private _platformAddress;
    uint256 private _extensionTimePeriod;

    mapping (ISouly => mapping (uint256 => address payable)) private _auction_vendor;
    mapping (ISouly => mapping (uint256 => uint256)) private _auction_platformCommissionPercent;
    mapping (ISouly => mapping (uint256 => uint256)) private _auction_closeTimestamp;
    mapping (ISouly => mapping (uint256 => address payable)) private _auction_bidder;
    mapping (ISouly => mapping (uint256 => uint256)) private _auction_amount;
    mapping (ISouly => mapping (uint256 => bool)) private _auction_claimed;
    mapping (ISouly => mapping (uint256 => bool)) private _auction_exist;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event AuctionCreated(ISouly indexed token, uint256 indexed  tokenId, uint256 closeTimestamp);
    event AuctionBid(ISouly indexed token, uint256 indexed  tokenId, address indexed bidder, uint256 amount);
    event AuctionClaimed(ISouly indexed token, uint256 indexed  tokenId, address indexed bidder, uint256 amount,
        uint256 platformCommision);

    modifier onlyAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "SoulyAuction: Caller is not a admin");
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "SoulyAuction: Caller is not a manager");
        _;
    }

    function initialize(address payable platformAddress_, uint256 platformCommissionPercent_, uint256 extensionTimePeriod_)
    initializer public{
        _platformAddress = platformAddress_;
        _platformCommissionPercent = platformCommissionPercent_;
        _extensionTimePeriod = extensionTimePeriod_;
        __ERC721Holder_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function setPlatformAddress(address payable platformAddress_) external onlyAdmin {
        _platformAddress = platformAddress_;
    }

    function platformAddress() public view returns(address payable){
        return _platformAddress;
    }

    function setPlatformCommissionPercent(uint256 platformCommissionPercent_) external onlyAdmin {
        _platformCommissionPercent = platformCommissionPercent_;
    }

    function platformCommissionPercent() public view returns(uint256){
        return _platformCommissionPercent;
    }


    function setExtensionTimePeriod(uint256 extensionTimePeriod_) external onlyAdmin {
        _extensionTimePeriod = extensionTimePeriod_;
    }

    function extensionTimePeriod() public view returns(uint256){
        return _extensionTimePeriod;
    }

    function createAuction(ISouly tokenContract, uint256 tokenId, uint256 secondsToClose)
    public onlyManager {
        require(!_auction_exist[tokenContract][tokenId], "SoulyAuction: Auction for this token already exist");
        require(tokenContract.ownerOf(tokenId) == address(this), "SoulyAuction: Auction not owns giving tokenId");

        uint256 closeTimestamp = block.timestamp + secondsToClose;

        _auction_vendor[tokenContract][tokenId] = tokenContract.creatorOf(tokenId);
        _auction_platformCommissionPercent[tokenContract][tokenId] = _platformCommissionPercent;
        _auction_closeTimestamp[tokenContract][tokenId] = closeTimestamp;
        _auction_bidder[tokenContract][tokenId] = payable(address(0));
        _auction_amount[tokenContract][tokenId] = 0;
        _auction_claimed[tokenContract][tokenId] = false;
        _auction_exist[tokenContract][tokenId] = true;

        emit AuctionCreated(tokenContract,tokenId,closeTimestamp);
    }

    function batchCreateAuction(ISouly tokenContract, uint256[] memory tokenId, uint256 secondsToClose) public {
        for (uint256 index; index < tokenId.length; index++){
            createAuction(tokenContract, tokenId[index], secondsToClose);
        }
    }

    function placeBid(ISouly tokenContract, uint256 tokenId) external payable {
        require(_auction_exist[tokenContract][tokenId], "SoulyAuction: Auction for this token not exist");
        require(!_auction_claimed[tokenContract][tokenId], "SoulyAuction: Auction was claimed");
        require(_auction_closeTimestamp[tokenContract][tokenId] >= block.timestamp,
            "SoulyAuction: Auction for this token is closed");
        require(msg.value > _auction_amount[tokenContract][tokenId],
            "SoulyAuction: Bid should be higher than current");

        uint256 refundAmount = _auction_amount[tokenContract][tokenId];
        address payable refundAddress = _auction_bidder[tokenContract][tokenId];

        _auction_bidder[tokenContract][tokenId] = payable(address(msg.sender));
        _auction_amount[tokenContract][tokenId] = msg.value;

        // Extend close time if it's required
        uint256 bidTimeOffset = _auction_closeTimestamp[tokenContract][tokenId].sub(block.timestamp);
        if (bidTimeOffset < _extensionTimePeriod) {
            _auction_closeTimestamp[tokenContract][tokenId] = _auction_closeTimestamp[tokenContract][tokenId].add(
                _extensionTimePeriod.sub(bidTimeOffset)
            );
        }

        refundAddress.transfer(refundAmount);

        emit AuctionBid(tokenContract, tokenId, msg.sender, msg.value);
    }

    function claimAuction(ISouly tokenContract, uint256 tokenId) public {
        require(_auction_exist[tokenContract][tokenId], "SoulyAuction: Auction not exist");
        require(!_auction_claimed[tokenContract][tokenId], "SoulyAuction: Auction was claimed");
        require(_auction_closeTimestamp[tokenContract][tokenId] < block.timestamp,
            "SoulyAuction: Auction is not closed");

        _auction_claimed[tokenContract][tokenId] = true;

        uint256 platformCommission;
        if (_auction_bidder[tokenContract][tokenId] != address(0)){
            platformCommission = _auction_amount[tokenContract][tokenId]
                .mul(_auction_platformCommissionPercent[tokenContract][tokenId])
                .div(10** COMMISSION_EXPONENT);

            tokenContract.safeTransferFrom(address(this), _auction_bidder[tokenContract][tokenId], tokenId);

            _platformAddress.transfer(platformCommission);
            _auction_vendor[tokenContract][tokenId].transfer(
                _auction_amount[tokenContract][tokenId].sub(platformCommission)
            );
        }else{
            tokenContract.burn(tokenId);
        }

        emit AuctionClaimed(tokenContract, tokenId, _auction_bidder[tokenContract][tokenId],
            _auction_amount[tokenContract][tokenId], platformCommission);
    }

    function batchClaimAuction(ISouly tokenContract, uint256[] memory tokenIds) external {
        for (uint256 index; index < tokenIds.length; index++){
            claimAuction(tokenContract, tokenIds[index]);
        }
    }

    function auction(ISouly tokenContract, uint256 tokenId) public view returns (
        address payable vendor,
        uint256 platformCommissionPercent_,
        uint256 closeTimestamp,
        address payable bidder,
        uint256 amount,
        bool claimed,
        bool exist
    ){
        require(_auction_exist[tokenContract][tokenId],"SoulyAuction: Auction not exist");
        vendor = _auction_vendor[tokenContract][tokenId];
        platformCommissionPercent_ = _auction_platformCommissionPercent[tokenContract][tokenId];
        closeTimestamp = _auction_closeTimestamp[tokenContract][tokenId];
        bidder = _auction_bidder[tokenContract][tokenId];
        amount = _auction_amount[tokenContract][tokenId];
        claimed = _auction_claimed[tokenContract][tokenId];
        exist = _auction_exist[tokenContract][tokenId];
    }
}