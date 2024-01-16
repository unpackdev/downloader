// SingleNFT Auction Contract 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC20.sol";

interface ISingleNFT {
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getCollectionRoyalties() external view returns (uint256);	
    function getCollectionOwner() external view returns (address);
    function creatorOf(uint256 _tokenId) external view returns (address);
	function itemRoyalties(uint256 _tokenId) external view returns (uint256);
}

contract SingleAuction is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeMath for uint256;    

    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public MIN_BID_INCREMENT_PERCENT = 10; // 1%
	uint256 public swapFee;	// 25 for 2.5%
	address public feeAddress;    	
    
    // AuctionBid struct to hold bidder and amount
    struct AuctionBid {
        address from;
        uint256 bidPrice;
    }

    // Auction struct which holds all the required info
    struct Auction {
        uint256 auctionId;
        address collectionId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address tokenAdr;
		uint256 startPrice;        
        address owner;
        bool active;       
    }

    // Array with all auctions
    Auction[] public auctions;
    
    // Mapping from auction index to user bids
    mapping (uint256 => AuctionBid[]) public auctionBids;
    
    // Mapping from owner to a list of owned auctions
    mapping (address => uint256[]) public ownedAuctions;
    
    event AuctionBidSuccess(address _from, Auction auction, uint256 price, uint256 _bidIndex);

    // AuctionCreated is fired when an auction is created
    event AuctionCreated(Auction auction);

    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(Auction auction);

    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(address buyer, uint256 price, Auction auction);

    function initialize(
        address _feeAddress
    ) public initializer {
        __Ownable_init();
        require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
        swapFee = 25;
    }	
    
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0x0), "invalid address");		
        feeAddress = _feeAddress;		
    }
    function setFeePercent(uint256 _swapFee) external onlyOwner {		
		require(_swapFee < 1000 , "invalid percent");
        swapFee = _swapFee;
    }

    /*
     * @dev Creates an auction with the given informatin
     * @param _tokenRepositoryAddress address of the TokenRepository contract
     * @param _tokenId uint256 of the deed registered in DeedRepository
     * @param _startPrice uint256 starting price of the auction
     * @return bool whether the auction is created
     */
    function createAuction(address _collectionId, uint256 _tokenId, address _tokenAdr, uint256 _startPrice, uint256 _startTime, uint256 _endTime) 
        onlyTokenOwner(_collectionId, _tokenId) public 
    {   
        require(block.timestamp < _endTime, "end timestamp have to be bigger than current time");
        
        ISingleNFT nft = ISingleNFT(_collectionId); 

        uint256 auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.auctionId = auctionId;
        newAuction.collectionId = _collectionId;
        newAuction.tokenId = _tokenId;
        newAuction.startPrice = _startPrice;
        newAuction.tokenAdr = _tokenAdr;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = msg.sender;        
        newAuction.active = true;
        
        auctions.push(newAuction);        
        ownedAuctions[msg.sender].push(auctionId);
        
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);        
        emit AuctionCreated(newAuction);       
    }
    
    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint256 ID of the created auction
     */
    function finalizeAuction(uint256 _auctionId) public {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;
        require(msg.sender == myAuction.owner || msg.sender == owner(), "only auction owner can finalize");
        
        // if there are no bids cancel
        if(bidsLength == 0) {
            ISingleNFT(myAuction.collectionId).safeTransferFrom(address(this), myAuction.owner, myAuction.tokenId);
            auctions[_auctionId].active = false;           
            emit AuctionCanceled(auctions[_auctionId]);
        }else{
            // 2. the money goes to the auction owner
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            
            // % commission cut
            uint256 collectionRoyalties = getCollectionRoyalties(myAuction.collectionId);
            address collectionOwner = getCollectionOwner(myAuction.collectionId);

            uint256 nftRoyalty = getNFTRoyalties(myAuction.collectionId, myAuction.tokenId);
            address nftCreator = getNFTCreator(myAuction.collectionId, myAuction.tokenId);


            uint256 _feeValue = lastBid.bidPrice.mul(swapFee).div(PERCENTS_DIVIDER); 
            uint256 _collectionOwnerValue = lastBid.bidPrice.mul(collectionRoyalties).div(PERCENTS_DIVIDER);
            uint256 _nftCreatorValue = lastBid.bidPrice.mul(nftRoyalty).div(PERCENTS_DIVIDER);
            uint256 _sellerValue = lastBid.bidPrice.sub(_feeValue).sub(_collectionOwnerValue).sub(_nftCreatorValue);
            
            if (myAuction.tokenAdr == address(0x0)) {                
                
                (bool auctionResult, ) = payable(myAuction.owner).call{value: _sellerValue}("");
        		require(auctionResult, "Failed to send coin to item owner"); 

                if(_feeValue > 0){
                    (bool result, ) = payable(feeAddress).call{value: _feeValue}("");
        		    require(result, "Failed to send fee to feeAddress");        
                }
                if(_collectionOwnerValue > 0){
                    (bool result, ) = payable(collectionOwner).call{value: _collectionOwnerValue}("");
        		    require(result, "Failed to send collection royalties to collectionOwner");        
                }
                if(_nftCreatorValue > 0){
                    (bool result, ) = payable(nftCreator).call{value: _nftCreatorValue}("");
        		    require(result, "Failed to send royalty to nft creator");        
                }                      
                
            } else {
                IERC20 governanceToken = IERC20(myAuction.tokenAdr);

                require(governanceToken.transfer(myAuction.owner, _sellerValue), "transfer to seller failed");
                if(_feeValue > 0) require(governanceToken.transfer(feeAddress, _feeValue)); 
                if(_collectionOwnerValue > 0) require(governanceToken.transfer(collectionOwner, _collectionOwnerValue));
                if(_nftCreatorValue > 0) require(governanceToken.transfer(nftCreator, _nftCreatorValue));              
            }
            
            // approve and transfer from this contract to the bid winner 
            ISingleNFT(myAuction.collectionId).safeTransferFrom(address(this), lastBid.from, myAuction.tokenId);		
            auctions[_auctionId].active = false;

            emit AuctionFinalized(lastBid.from,lastBid.bidPrice, myAuction);
        }
    }
    
    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint256 ID of the created auction
     */
    function bidOnAuction(uint256 _auctionId, uint256 amount) external payable {
        // owner can't bid on their auctions
        require(_auctionId <= auctions.length && auctions[_auctionId].auctionId == _auctionId, "Could not find item");
        Auction memory myAuction = auctions[_auctionId];
        require(myAuction.owner != msg.sender, "owner can not bid");
        require(myAuction.active, "not exist");

        // if auction is expired
        require(block.timestamp < myAuction.endTime, "auction is over");
        require(block.timestamp >= myAuction.startTime, "auction is not started");

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myAuction.startPrice;
        AuctionBid memory lastBid;

        // there are previous bids
        if( bidsLength > 0 ) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount = lastBid.bidPrice.mul(PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT).div(PERCENTS_DIVIDER);
        }

        if (myAuction.tokenAdr == address(0x0)) {
            require(msg.value >= tempAmount, "too small amount");
            require(msg.value >= amount, "too small balance");
            if( bidsLength > 0 ) {                
                (bool result, ) = payable(lastBid.from).call{value: lastBid.bidPrice}("");
        		require(result, "Failed to send coin to last bidder");
            }

        } else {
            // check if amount is greater than previous amount  
            require(amount >= tempAmount, "too small amount");

            IERC20 governanceToken = IERC20(myAuction.tokenAdr);
            require(governanceToken.transferFrom(msg.sender, address(this), amount), "transfer to contract failed");
        
            if( bidsLength > 0 ) {
                require(governanceToken.transfer(lastBid.from, lastBid.bidPrice), "refund to last bidder failed");
            }
        }        

        // insert bid 
        AuctionBid memory newBid;
        newBid.from = msg.sender;
        newBid.bidPrice = amount;
        auctionBids[_auctionId].push(newBid);
        emit AuctionBidSuccess(msg.sender, myAuction, newBid.bidPrice, bidsLength);
    }



    modifier AuctionExists(uint256 auctionId){
        require(auctionId <= auctions.length && auctions[auctionId].auctionId == auctionId, "Could not find item");
        _;
    }


    /**
     * @dev Gets the length of auctions
     * @return uint256 representing the auction count
     */
    function getAuctionsLength() public view returns(uint) {
        return auctions.length;
    }
    
    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint256 ID of the auction
     */
    function getBidsAmount(uint256 _auctionId) public view returns(uint) {
        return auctionBids[_auctionId].length;
    } 
    
    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getOwnedAuctions(address _owner) public view returns(uint[] memory) {
        uint[] memory ownedAllAuctions = ownedAuctions[_owner];
        return ownedAllAuctions;
    }
    
    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId uint256 of the auction owner
     * @return amount uint256, address of last bidder
     */
    function getCurrentBids(uint256 _auctionId) public view returns(uint256, address) {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength >= 0) {
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }    
        return (0, address(0));
    }

    function getCollectionRoyalties(address collection) view private returns(uint256) {
        ISingleNFT nft = ISingleNFT(collection); 
        try nft.getCollectionRoyalties() returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }
    function getCollectionOwner(address collection) view private returns(address) {
        ISingleNFT nft = ISingleNFT(collection); 
        try nft.getCollectionOwner() returns (address ownerAddress) {
            return ownerAddress;
        } catch {
            return address(0x0);
        }
    }

    function getNFTRoyalties(address collection, uint256 tokenId) view private returns(uint256) {
        ISingleNFT nft = ISingleNFT(collection); 
        try nft.itemRoyalties(tokenId) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }
    function getNFTCreator(address collection, uint256 tokenId) view private returns(address) {
        ISingleNFT nft = ISingleNFT(collection); 
        try nft.creatorOf(tokenId) returns (address creatorAddress) {
            return creatorAddress;
        } catch {
            return address(0x0);
        }
    }
    
    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint256 total number of auctions
     */
    function getAuctionsAmount(address _owner) public view returns(uint) {
        return ownedAuctions[_owner].length;
    }

    modifier onlyAuctionOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    modifier onlyTokenOwner(address _collectionId, uint256 _tokenId) {
        address tokenOwner = IERC721(_collectionId).ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        _;
    }
    /**
     * @dev To receive ETH
     */
    receive() external payable {}
}