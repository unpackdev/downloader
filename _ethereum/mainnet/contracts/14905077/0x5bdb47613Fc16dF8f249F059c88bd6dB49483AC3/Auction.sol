pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED
/*
 * (c) Copyright 2022 Masalsa, Inc., all rights reserved.
  You have no rights, whatsoever, to fork, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.
  By using this file/contract, you agree to the Customer Terms of Service at nftdeals.xyz
  THE SOFTWARE IS PROVIDED AS-IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  This software is Experimental, use at your own risk!
 */

import "./console.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./Multicall.sol";
import "./AuctionFactory.sol";

contract Auction is IERC721Receiver, AccessControl, Multicall {
    using Strings for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private redCarpetSet;
    enum ListState { CLOSE, OPEN }
    ListState public redCarpetState = ListState.OPEN;

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    enum FlexibilityType { DYNAMIC, STATIC }
    FlexibilityType public auctionFeeType = FlexibilityType.STATIC;
    uint public staticFeeInBasisPoints = 10_000;

    uint public listerTakeInPercentage;
    IERC20 public immutable weth;
    uint public immutable createdAt;

    address public nftOwner;
    IERC721 public nftContract;
    uint public tokenId;
    uint public minimumBidIncrement;
    uint public auctionTimeIncrementOnBid;

    AuctionFactory public auctionFactory;
    bool public _weHavePossessionOfNft;
    uint public expiration;
    address public winningAddress;
    uint public highestBid;
    uint public feePaidByHighestBid;
    uint public _platformFeesAccumulated;
    uint public _listerFeesAccumulated;
    uint public maxBid;
    bool public qualifiesForRewards;
    bool public paused;


    event Bid(address from, address previousWinnersAddress, uint amount, uint secondsLeftInAuction);
    event MoneyOut(address to, uint amount);
    event FailedToSendMoney(address to, uint amount);
    event NftOut(address to, uint tokenId);
    event NftIn(address from, uint tokenId);
    event AuctionExtended(uint from, uint to);

    struct AllData {
        FlexibilityType auctionFeeType;
        uint staticFeeInBasisPoints;
        uint feeInBasisPoints;
        uint listerTakeInPercentage;
        uint dynamicProtocolFeeInBasisPoints;
        IERC20 weth;
        uint minimumBidIncrement;
        uint auctionTimeIncrementOnBid;
        IERC721 nftContract;
        uint tokenId;
        bool _weHavePossessionOfNft;
        uint expiration;
        address winningAddress;
        uint highestBid;
        uint feePaidByHighestBid;
        uint _platformFeesAccumulated;
        uint _listerFeesAccumulated;
        uint maxBid;
        uint secondsLeftInAuction;
        uint currentReward;
        uint rewards;
        uint wethBalance;
        string name;
        string symbol;
        string tokenURI;
        uint createdAt;
        address nftOwner;
        AuctionFactory auctionFactory;
        bool qualifiesForRewards;
        bool paused;
        uint redCarpetLength;
        uint redCarpetState;
        bool presentInRedCarpet;
    }

    constructor(
        address _nftContractAddress,
        uint _tokenId,
        uint startBidAmount,
        uint _auctionTimeIncrementOnBid,
        uint _minimumBidIncrement,
        address _nftOwner,
        address _wethAddress,
        address _adminOneAddress,
        address _adminTwoAddress,
        address _auctionFactoryAddress,
        FlexibilityType _auctionFeeType,
        uint _staticFeeInBasisPoints){
            nftContract = IERC721(_nftContractAddress);
            tokenId = _tokenId;
            nftOwner = _nftOwner;

            require(nftContract.ownerOf(tokenId) == nftOwner, "you are not the owner of this nft");

            listerTakeInPercentage = 50;
            highestBid = startBidAmount;
            feePaidByHighestBid = 0;
            maxBid = highestBid;
            auctionTimeIncrementOnBid = _auctionTimeIncrementOnBid;
            minimumBidIncrement = _minimumBidIncrement;
            createdAt = block.timestamp;

            weth = IERC20(_wethAddress);
            auctionFactory = AuctionFactory(_auctionFactoryAddress);

            auctionFeeType = _auctionFeeType;
            staticFeeInBasisPoints = _staticFeeInBasisPoints;

            _setupRole(DEFAULT_ADMIN_ROLE, _adminOneAddress);
            _setupRole(DEFAULT_ADMIN_ROLE, _adminTwoAddress);

            _setupRole(TREASURY_ROLE, _adminOneAddress);
            _setupRole(TREASURY_ROLE, _adminTwoAddress);

            _setupRole(MODERATOR_ROLE, _adminOneAddress);
            _setupRole(MODERATOR_ROLE, _adminTwoAddress);
    }

    function updateAuction(uint _minimumBidIncrement,
        uint _auctionTimeIncrementOnBid,
        address _nftContractAddress,
        uint _tokenId,
        address _nftOwner,
        uint startBidAmount,
        FlexibilityType _auctionFeeType,
        uint _staticFeeInBasisPoints
    ) auctionHasNotStarted youAreTheNftOwner public {
        nftContract = IERC721(_nftContractAddress);
        tokenId = _tokenId;
        nftOwner = _nftOwner;

        require(nftContract.ownerOf(tokenId) == nftOwner, "you are not the owner of this nft");

        auctionTimeIncrementOnBid = _auctionTimeIncrementOnBid;
        minimumBidIncrement = _minimumBidIncrement;
        highestBid = startBidAmount;
        maxBid = highestBid;
        auctionFeeType = _auctionFeeType;
        staticFeeInBasisPoints = _staticFeeInBasisPoints;
    }

    function startAuction() youAreTheNftOwner auctionHasNotStarted external{
        address operatorAddress = nftContract.getApproved(tokenId);
        require(operatorAddress == address(this), 'approval not found');
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        expiration = block.timestamp + auctionTimeIncrementOnBid;
        _weHavePossessionOfNft = true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 _tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        require(_weHavePossessionOfNft == false, "we already have an nft");
        require(_tokenId == tokenId, "this is the wrong nft tokenId");
        require(msg.sender == address(nftContract), "this is the wrong nft contract");
        emit NftIn(from, _tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    modifier auctionHasNotStarted() {
        require(expiration == 0, "expiration has started");
        _;
    }

    modifier auctionHasStarted() {
        require(expiration != 0, 'auction has not started');
        _;
    }

    modifier auctionHasEnded() {
        require(block.timestamp > expiration, "auction is still active");
        _;
    }

    modifier auctionHasNotEnded() {
        require(expiration > block.timestamp, "auction has expired");
        _;
    }

    modifier auctionIsPaused() {
        require(paused == true, "auction is not paused");
        _;
    }

    modifier auctionIsNotPaused() {
        require(paused == false, "auction is paused");
        _;
    }

    modifier thereIsNoWinner() {
        require(winningAddress == address(0), "there is a winner");
        _;
    }

    modifier thereIsAWinner() {
        require(winningAddress != address(0), 'there is no winner');
        _;
    }

    modifier youAreTheWinner() {
        require(msg.sender == winningAddress, "you are not the winner");
        _;
    }

    modifier youAreTheNftOwner() {
        require(msg.sender == nftOwner, "you are not the nft owner");
        _;
    }

    modifier weHavePossessionOfNft() {
        require(_weHavePossessionOfNft == true, "we dont have the nft");
        _;
    }

    function calculateFeeFromBasisPoints(uint amount, uint bp) pure public returns(uint){
        return (amount * bp) / 10000;
    }

    function currentReward() view public returns(uint){
        uint reward = 0;
        if(expiration > block.timestamp){
            reward = (expiration - block.timestamp) / 60 / 60;
        }
        console.log("calculated currentReward to be: ");
        console.log(reward);
        return reward;
    }

    function giveReward() private {
        if(qualifiesForRewards == true){
            console.log("you qualify for rewards");
            uint reward = currentReward();
            if(reward > 0){
                if(redCarpetSet.contains(msg.sender)){
                    reward = reward * 2;
                }
                auctionFactory.giveReward(msg.sender, reward);
            }
        }else {
            console.log('this auction does not qualify for rewards');
        }
    }

    function setQualifiesForRewards(bool _qualifies) public onlyRole(MODERATOR_ROLE) {
        qualifiesForRewards = _qualifies;
    }

    function bid() auctionHasStarted auctionHasNotEnded auctionIsNotPaused external {
        uint totalNextBid = highestBid + minimumBidIncrement;
        uint platformFee;
        uint listerFee;
        console.log("totalNextBid: ");
        console.log(totalNextBid);

        require(weth.allowance(msg.sender, address(this)) >= totalNextBid, 'WETH approval not found');
        require(weth.balanceOf(msg.sender) >= totalNextBid, 'WETH insufficient funds');
        require(weth.transferFrom(msg.sender, address(this), totalNextBid), 'WETH transfer failed!');

        emit Bid(msg.sender, winningAddress, totalNextBid, secondsLeftInAuction());

        console.log("refunding previous bidder: ");
        console.log(highestBid);
        console.log(feePaidByHighestBid);

        uint amountToRefund = highestBid-feePaidByHighestBid;
        console.log(amountToRefund);

        _sendMoney(winningAddress, amountToRefund);
        giveReward();

        uint feeInBasisPoints = getFeeInBasisPoints();
        uint protocolFee = calculateFeeFromBasisPoints(totalNextBid, feeInBasisPoints);
        listerFee = (protocolFee * listerTakeInPercentage) / 100;
        platformFee = protocolFee - listerFee;

        _platformFeesAccumulated += platformFee;
        _listerFeesAccumulated += listerFee;

        highestBid = totalNextBid; // new highest bid
        feePaidByHighestBid = platformFee + listerFee; // fee paid by new highest bid
        winningAddress = msg.sender;

        console.log('increasing expiration timestamp');
        console.log(block.timestamp);
        console.log(auctionTimeIncrementOnBid);
        console.log(block.timestamp + auctionTimeIncrementOnBid);
        emit AuctionExtended(expiration, block.timestamp + auctionTimeIncrementOnBid);
        expiration = block.timestamp + auctionTimeIncrementOnBid;

        maxBid = highestBid;
    }

    function secondsLeftInAuction() public view returns(uint) {
        console.log('in secondsLeftInAuction');
        console.log(expiration);
        console.log(block.timestamp);
        if(expiration == 0){
            return 0;
        } else if(expiration < block.timestamp){
            return 0;
        } else {
            return expiration - block.timestamp;
        }
    }

    function hoursLeftInAuction() public view returns(uint) {
        uint secsLeft = secondsLeftInAuction();
        uint hoursLeft = secsLeft / 1 hours;
        return hoursLeft;
    }

    function doEmptyTransaction() external { }

    function claimNftWhenNoAction() auctionHasStarted auctionHasEnded
        thereIsNoWinner youAreTheNftOwner weHavePossessionOfNft external {
            _transfer();
    }

    function claimNftUponWinning() auctionHasStarted auctionHasEnded
        thereIsAWinner youAreTheWinner weHavePossessionOfNft external {
            _transfer();
    }

    function claimPlatformFees() onlyRole(TREASURY_ROLE) external {
        uint amountToSend = _platformFeesAccumulated;
        _platformFeesAccumulated = 0;
        _sendMoney(msg.sender, amountToSend);
    }

    function claimListerFees() youAreTheNftOwner external {
        uint amountToSend = _listerFeesAccumulated;
        _listerFeesAccumulated = 0;
        _sendMoney(msg.sender, amountToSend);
    }

    function claimFinalBidAmount() auctionHasStarted auctionHasEnded
        thereIsAWinner youAreTheNftOwner public {
            require(highestBid != 0, 'the highest bid is 0!');
            uint bidAmount = highestBid;
            bidAmount -= feePaidByHighestBid;
            highestBid = 0;
            _sendMoney(msg.sender, bidAmount);
    }

    function _transfer() private {
        _weHavePossessionOfNft = false;
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NftOut(msg.sender, tokenId);
    }

    function _sendMoney(address recipient, uint amount) private {
        if(recipient == address(0)){
            console.log('wont sent money as recipient is 0');
        } else if(amount == 0){
            console.log('wont send money as amount is 0');
        }else{
            console.log('in sendmoney');
            console.log(recipient);
            console.log(amount);
            bool result = weth.transfer(recipient, amount);
            if(result == true){
                emit MoneyOut(recipient, amount);
            }else{
                emit FailedToSendMoney(recipient, amount);
            }
        }
    }

    function selfDestruct() onlyRole(DEFAULT_ADMIN_ROLE) external {
        try nftContract.safeTransferFrom(address(this), msg.sender, tokenId) {
            console.log('sent nft');
        }catch {
            console.log('unable to get nft');
        }
        try weth.balanceOf(address(this)) returns (uint bal) {
            try weth.transfer(msg.sender, bal) {
                console.log('transfered weth');
            }catch {
                console.log('unable to transfer weth');
            }
        }catch{
            console.log('unable to get balance');
        }
        selfdestruct(payable(msg.sender));
    }

    function setListerTakeInPercentage(uint val) onlyRole(MODERATOR_ROLE) external {
        listerTakeInPercentage = val;
    }

    function setPaused(bool val) onlyRole(MODERATOR_ROLE) external {
        paused = val;
    }

    function setAuctionFactory(address _auctionFactoryAddress) onlyRole(MODERATOR_ROLE) external {
        auctionFactory = AuctionFactory(_auctionFactoryAddress);
    }

    function setMinimumBidIncrement(uint _minimumBidIncrement) onlyRole(MODERATOR_ROLE) public {
        minimumBidIncrement = _minimumBidIncrement;
    }

    function setAuctionTimeIncrementOnBid(uint _auctionTimeIncrementOnBid) onlyRole(MODERATOR_ROLE) public {
        auctionTimeIncrementOnBid = _auctionTimeIncrementOnBid;
    }

    function setStaticFeeInBasisPoints(uint _staticFeeInBasisPoints) onlyRole(MODERATOR_ROLE) public {
        staticFeeInBasisPoints = _staticFeeInBasisPoints;
    }

    function setAuctionFeeType(FlexibilityType _auctionFeeType) onlyRole(MODERATOR_ROLE) public {
        auctionFeeType = _auctionFeeType;
    }

    function getFeeInBasisPoints() view public returns(uint){
        if(auctionFeeType == FlexibilityType.DYNAMIC){
            return getDynamicProtolFeeInBasisPoints();
        }else if(auctionFeeType == FlexibilityType.STATIC){
            return staticFeeInBasisPoints;
        }else {
            return 10_000;
        }
    }

    function getDynamicProtolFeeInBasisPoints() view public returns(uint){
        console.log("in getDynamicProtolFeeInBasisPoints");
        uint hoursLeft = hoursLeftInAuction();
        console.log(hoursLeft);
        uint platformFeeInBasisPoints;
        if(hoursLeft>=24){
            platformFeeInBasisPoints = 400;
        }else{
            platformFeeInBasisPoints= ((uint(2400) - (hoursLeft*uint(100))) / uint(24)) * uint(100);
        }
        console.log(platformFeeInBasisPoints);
        return platformFeeInBasisPoints;
    }

    function getAllData(address me) public view returns(AllData memory) {
        AllData memory data;
        data.auctionFeeType = auctionFeeType;
        data.staticFeeInBasisPoints = staticFeeInBasisPoints;
        data.feeInBasisPoints = getFeeInBasisPoints();
        data.dynamicProtocolFeeInBasisPoints = getDynamicProtolFeeInBasisPoints();
        data.listerTakeInPercentage = listerTakeInPercentage;
        data.weth = weth;
        data.minimumBidIncrement = minimumBidIncrement;
        data.auctionTimeIncrementOnBid = auctionTimeIncrementOnBid;
        data.nftContract = nftContract;
        data.tokenId = tokenId;
        data._weHavePossessionOfNft = _weHavePossessionOfNft;
        data.expiration = expiration;
        data.winningAddress = winningAddress;
        data.highestBid = highestBid;
        data.feePaidByHighestBid = feePaidByHighestBid;
        data._platformFeesAccumulated = _platformFeesAccumulated;
        data._listerFeesAccumulated = _listerFeesAccumulated;
        data.maxBid = maxBid;
        data.secondsLeftInAuction = secondsLeftInAuction();
        data.currentReward = currentReward();
        data.rewards = auctionFactory.rewards(me);
        data.wethBalance = weth.balanceOf(me);
        if(nftContract.supportsInterface(type(IERC721Metadata).interfaceId) == true){
            IERC721Metadata nft_contract_meta = IERC721Metadata(address(nftContract));
            data.name = nft_contract_meta.name();
            data.symbol = nft_contract_meta.symbol();
            data.tokenURI = nft_contract_meta.tokenURI(tokenId);
        }
        data.createdAt = createdAt;
        data.nftOwner = nftOwner;
        data.auctionFactory = auctionFactory;
        data.qualifiesForRewards = qualifiesForRewards;
        data.paused = paused;
        data.redCarpetLength = redCarpetSet.length();
        data.redCarpetState = uint(redCarpetState);
        data.presentInRedCarpet = redCarpetSet.contains(me);
        return data;
    }

    function getRedCarpet() view public returns(address[] memory) {
        return redCarpetSet.values();
    }

    function getRedCarpetLength() view public returns(uint) {
        return redCarpetSet.length();
    }

    function joinRedCarpet() public{
        require(redCarpetState == ListState.OPEN, "Red Carpet is Closed");
        redCarpetSet.add(msg.sender);
    }

    function checkRedCarpet(address _address) view public returns(bool) {
        return redCarpetSet.contains(_address);
    }

    function changeRedCarpetState(uint _newState) public onlyRole(MODERATOR_ROLE)  {
        redCarpetState = ListState(_newState);
    }
}
