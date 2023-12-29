// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Admins.sol";

error WithdrawBidFailed();
error BidWithValueTooLow();
error BidWithStepTooLow();
error BidWithBadAmount();
error BidWithBadCount();
error AuctionNotInit();
error AuctionNotOpen();
error AuctionClosed();
error AuctionAlreadyInit();
error NewAuctionNotInit();

contract AuctionMulti is Admins {

    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct Auction {
        uint64 startAt;
        uint64 endAt;
        uint256 count;
        uint256 minBid;
        bool closed;
        bool initialized;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid[50]) public bids;

    event NewBid(uint256 auctionId, address wallet, uint256 amount);
    event RefundBid(uint256 auctionId, address wallet, uint256 amount);

    address public resolverAddress;

    modifier onlyOwnerOrAdminsOrResolver() {
        require(isAdmin(_msgSender()) || owner() == _msgSender() || resolverAddress == _msgSender(), "Sender: is not resolverAddress");
        _;
    }

    modifier auctionAvailable(uint256 _auctionId){
        if(!isAuctionInitialized(_auctionId)){
            revert AuctionNotInit();
        }
        if(isAuctionClosed(_auctionId)){
            revert AuctionClosed();
        }
        if(!isAuctionOpen(_auctionId)){
            revert AuctionNotOpen();
        }
        _;
    }

    function configureAuction(uint256 _auctionId, Auction memory _newAuction) public virtual onlyOwnerOrAdminsOrResolver {
        if(auctions[_auctionId].initialized){
            revert AuctionAlreadyInit();
        }
        if(!_newAuction.initialized){
            revert NewAuctionNotInit();
        }

        auctions[_auctionId] = _newAuction;

        for(uint256 i = 0; i < _newAuction.count; i++){
            bids[_auctionId][i].bidder = address(this);
            bids[_auctionId][i].amount = _newAuction.minBid;
        }
    }

    function editAuction(uint256 _auctionId, Auction memory _auction) public virtual onlyOwnerOrAdminsOrResolver {
        if(!auctions[_auctionId].initialized){
            revert AuctionNotInit();
        }
        if(auctions[_auctionId].closed || _auction.closed){
            revert AuctionClosed();
        }
        if(!_auction.initialized){
            revert NewAuctionNotInit();
        }

        auctions[_auctionId] = _auction;
    }

    function closeAuction(uint256 _auctionId) public virtual onlyOwnerOrAdminsOrResolver {
        if(!auctions[_auctionId].initialized){
            revert AuctionNotInit();
        }
        if(auctions[_auctionId].closed){
            revert AuctionClosed();
        }

        auctions[_auctionId].closed = true;
    }

    function SendBid(uint256 _auctionId, uint256 _count) public payable virtual auctionAvailable(_auctionId) {
        uint256 amount = msg.value;

        if(_count > auctions[_auctionId].count || _count <= 0){
            revert BidWithBadCount();
        }

        unchecked{
            uint256 value = amount / _count;

            for(uint256 i = 0; i < _count; i++){
                _sendBid(_auctionId, value);
            }
        }

    }

    function _sendBid(uint256 _auctionId, uint256 _amount) internal virtual {

        uint256 minBidValue = getMinBid(_auctionId);

        if(minBidValue >= _amount){
            revert BidWithValueTooLow();
        }

        uint256 currentIndex = _getBidIndex(_auctionId, _amount);

        if(currentIndex >= auctions[_auctionId].count){
            revert BidWithValueTooLow();
        }

        if(_amount < bids[_auctionId][currentIndex].amount + 0.001 ether){
            revert BidWithStepTooLow();
        }

        if(_amount % 0.001 ether != 0){
            revert BidWithBadAmount();
        }

        // save the last bidder before moving
        Bid memory lastBider = bids[_auctionId][auctions[_auctionId].count - 1];

        // moving old auctions in the bids array
        for (uint256 i = auctions[_auctionId].count - 1 ; i > currentIndex; i--) {
            bids[_auctionId][i] = bids[_auctionId][i - 1];
        }

        // add new bidder in the bids array
        bids[_auctionId][currentIndex] = Bid(_msgSender(), _amount);

        emit NewBid(_auctionId, _msgSender(), _amount);

        // refund the last bidder of the auction
        if(lastBider.bidder != address(this)){
            emit RefundBid(_auctionId, lastBider.bidder, lastBider.amount);

            _withdraw(lastBider.bidder, lastBider.amount);
        }

    }

    function _getBidIndex(uint256 _auctionId,uint256 _amount) private view returns(uint256){
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < auctions[_auctionId].count; i++) {
            if(_amount > bids[_auctionId][i].amount) {
                currentIndex = i;
                break;
            }
            if(_amount == bids[_auctionId][i].amount){
                currentIndex += 1;
            }
        }
        return currentIndex;
    }

    function getBids(uint256 _auctionId) public view returns (Bid[] memory) {
        Bid[] memory currentBids = new Bid[](auctions[_auctionId].count);
        for(uint256 i = 0; i < auctions[_auctionId].count; i++){
            currentBids[i] = bids[_auctionId][i];
        }
        return currentBids;
    }

    function getMinBid(uint256 _auctionId) public view returns(uint256){
        return bids[_auctionId][auctions[_auctionId].count - 1].amount;
    }

    function isBidValid(uint256 _auctionId, uint256 _count, uint256 _totalAmount) public view returns(bool){
        if(_count > auctions[_auctionId].count || _count <= 0){
            return false;
        }

        unchecked{
            uint256 amount = _totalAmount / _count;

            Bid[] memory _bids = new Bid[](50);
            for(uint256 i = 0; i < auctions[_auctionId].count; i++){
                _bids[i] = bids[_auctionId][i];
            }

            for(uint256 j = 0; j < _count; j++){

                uint256 minBidValue = _bids[auctions[_auctionId].count - 1].amount;

                if(minBidValue >= amount){
                    return false;
                }

                uint256 currentIndex = 0;
                for (uint256 i = 0; i < auctions[_auctionId].count; i++) {
                    if(amount > _bids[i].amount) {
                        currentIndex = i;
                        break;
                    }
                    if(amount == _bids[i].amount){
                        currentIndex += 1;
                    }
                }

                if(currentIndex >= auctions[_auctionId].count || amount < _bids[currentIndex].amount + 0.001 ether || amount % 0.001 ether != 0){
                    return false;
                }

                // moving old auctions in the bids array
                for (uint256 i = auctions[_auctionId].count - 1 ; i > currentIndex; i--) {
                    _bids[i] = _bids[i - 1];
                }

                // add new bidder in the bids array
                _bids[currentIndex] = Bid(_msgSender(), amount);
            }
        }
        return true;
    }

    function isAuctionInitialized(uint256 _auctionId) public view returns(bool){
        return auctions[_auctionId].initialized;
    }

    function isAuctionClosed(uint256 _auctionId) public view returns(bool){
        return auctions[_auctionId].closed;
    }

    function isAuctionOpen(uint256 _auctionId) public view returns(bool){
        return block.timestamp >= auctions[_auctionId].startAt && block.timestamp <= auctions[_auctionId].endAt;
    }

    function setResolverAddress(address _resolverAddress) public onlyOwnerOrAdmins {
        resolverAddress = _resolverAddress;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if(!success){
            revert WithdrawBidFailed();
        }
    }
}
