// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./ISmileToken.sol";

contract SmileAuction is Ownable, ReentrancyGuard, IERC721Receiver{
    using SafeMath for uint256;

    ISmileToken public token;
    uint256 public bidIncrementPercentage;
    address public treasuryWallet = 0x80D9d964779845d82D9232C058dC240cb66a6D5E;
    
    struct Auction {
        address owner;
        // The minimum price accepted in an auction
        uint256 minNFTPrice;
        uint256 start;
        uint256 end;
        bool canceled;
        address highestBidderAddress;
        uint256 highestBidAmount;
    }

    // mapping of token ID to Auction Structure
    mapping (uint256 => Auction) public auction;

    event LogAuction(address creator, uint256 tokenID, uint256 startTime, uint256 endTime, bool status);
    event LogBid(uint256 tokenID, address bidder, uint256 amount);
    event LogWithdrawal(uint tokenID, address withdrawalAccount, uint256 amount);
    event LogAuctionWinner(uint tokenID, address winnerAddress);
    event LogCanceled(uint256 tokenID);   // modifier onlyOwner {
    event LogCharity(address creator, uint256 tokenID, bool isTransferToTheSmileOf);

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }  

    constructor (address _token, uint256 _bidIncrementPercentage) {
        require(_token != address(0), "owner is zero address");
        require(_bidIncrementPercentage > 0, "Bid increament should be more then 0%");
        token = ISmileToken(_token);
        bidIncrementPercentage = _bidIncrementPercentage; // for 5% => 500
    }

    function setTreasuryAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Not allow 0 address");
        treasuryWallet = _newAddress;
    }

    function createAuction(uint256 _minNFTPrice, uint256 _start, uint256 _end, string memory _uri) public onlyOwner {

        // mint NFT 
        uint256 tokenID;
        bool isCharity;
        if((token.totalSupply()+1).mod(5) == 0 && token.totalSupply() > 1){
            tokenID = token.mint(msg.sender);
            isCharity = true;
            // tokenID = token.totalSupply() - 1;
            // emit LogCharity(msg.sender, tokenID, true);
        }  else {
            tokenID = token.mint(address(this));
            isCharity = false;
            // Create NFT bid by contract owner
            auction[tokenID] = Auction({
                owner: msg.sender,
                minNFTPrice: _minNFTPrice,
                start: _start,
                end: _end,
                canceled: false,
                highestBidderAddress: address(0),
                highestBidAmount: 0
            });
        }

        token.setTokenUri(tokenID, _uri);

        emit LogAuction(msg.sender, tokenID, _start, _end, isCharity);
       
    }

    function placeBid(uint256 _tokenID) public payable nonReentrant{
        Auction storage _auction = auction[_tokenID];
        
        require(block.timestamp >= _auction.start, "Auction not started yet");
        require(block.timestamp <= _auction.end, 'Auction expired');
        require(_auction.canceled == false, "Auction canceled");
        require(msg.sender != _auction.owner, "Owner cannot place bid");
        
        if(_auction.highestBidAmount > 0){
            uint256 amount =_auction.highestBidAmount;
            require(
                msg.value >= amount.add(amount.mul(bidIncrementPercentage).div(10000)),
                'Must send more than last bid by minBidIncrementPercentage amount'
            );
        } else{
            require(msg.value >= _auction.minNFTPrice, 'Must send at least minimum NFT price');
        }
        //refund second last highest bid amount
        payable(_auction.highestBidderAddress).transfer(_auction.highestBidAmount);
        
        _auction.highestBidderAddress = msg.sender;
        _auction.highestBidAmount = msg.value;

        emit LogBid(_tokenID, msg.sender, msg.value);
    }

    function cancelAuction(uint _tokenID) public onlyOwner {
        Auction storage _auction = auction[_tokenID];
        require(_auction.end > block.timestamp, "Auction already completed");
        //refund second last highest bid amount
        if(_auction.highestBidAmount > 0 && _auction.highestBidderAddress != address(0)){
            payable(_auction.highestBidderAddress).transfer(_auction.highestBidAmount);
        }
        _auction.canceled = true;
        emit LogCanceled(_tokenID);
    }

    function claimNFT(uint256 _tokenID) public nonReentrant {
        Auction storage _auction = auction[_tokenID];
        require(_auction.end < block.timestamp, "Auction still under progress");
        require(_auction.highestBidderAddress == msg.sender, "You are not winner" );
        payable(treasuryWallet).transfer(_auction.highestBidAmount);
    
        // Transfer NFT to winner
        token.safeTransferFrom(address(this), msg.sender, _tokenID);
        _auction.highestBidAmount = 0;
        _auction.highestBidderAddress = address(0);
        emit LogAuctionWinner(_tokenID, msg.sender);
    }
    
    function withdrawDust(address _to, uint256 _amount) external onlyOwner{
        uint256 balance = address(this).balance;
        require(balance >= _amount, "Balance should atleast equal to amount");
        payable(_to).transfer(_amount);
    }

    function withdrawNFT(address _to, uint256 _tokenID) external onlyOwner{
        Auction storage _auction = auction[_tokenID];
        require(_auction.end < block.timestamp, "Auction still running");
        require(_auction.highestBidderAddress == address(0), "Auction have a bidder");
        // Transfer NFT to contract
        token.safeTransferFrom(address(this), _to, _tokenID);
    }

}