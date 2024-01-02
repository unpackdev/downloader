// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "./SafeTransferLib.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./IRoyaltyEngineV1.sol";

interface IAccaAuction {
    error BidTooLow(uint256 listingId, uint256 bidAmount);
    error AlreadyInitialized();
    error ReentrantCall();
    error ListingNotActive(uint256 listingId);
    error NotOwner(address);
    error ListingAlreadyExists(uint256 listingId);
    error NonExistentListing(uint256 listingId);
    error ActiveListingNotReplaceable(uint256 listingId);
    error ActiveListingNotRemoveable(uint256 listingId);
    error ListingNotCompleted(uint256 listingId);
    error ArraysSizesDoNotMatch();
    error NotSupportedToken(address tokenContract);
    error NotOwnedByThis(address tokenContract, uint256 tokenId);
    error NoBids(uint256 listingId);
    error ClaimerNotLatestBidder(uint256 listingId, address claimer, address latestBidder);
    error ListingNotReturnable(uint256 listingId);
    error ListingNotClaimable(uint256 listingId);
    error NoZeroStartPrice();

    event ListingAdded(
        uint256 indexed listingId, 
        address indexed tokenContract, 
        uint256 indexed tokenId,
        address tokenProvider,
        uint256 startPrice,
        uint256 reservePrice
    );
    
    event OwnershipTransferred(address oldOwner, address newOwner);

    event EthTransferFailed(address to, uint256 amount);

    event RoyaltiesRetrieveError(
        address tokenContract, 
        uint256 tokenId, 
        uint256 amount, 
        bytes reason
    );

    event NFTTransferError(
        address tokenContract, 
        uint256 tokenId, 
        address to,
        bytes reason
    );

    struct Bid {
        address bidder;
        bool refunded;
        uint256 bidAmount;
    }

    struct BidStep {
        uint256 nextBidThreshold;
        uint256 stepSize;
    }

    struct ListingDetails {
        address contractAddres;
        uint256 tokenId;
        address tokenProvider;
        uint256 startPrice;
        uint256 reservePrice;
        uint256 extraTime;
    }

    function createListing(
        uint256 listingId,
        ListingDetails calldata listing
    ) external;

    function createListings(
        uint256[] calldata listingIds,
        ListingDetails[] calldata listings
    ) external;

    function replaceListing(
        uint256 listingId,
        ListingDetails memory listing
    ) external;

    function removeListing(uint256 listingId) external;

    function getListing(uint256 listingId) external view returns (ListingDetails memory);

    function isActive(uint256 listingId) external view returns(bool);

    function listingEndTime(uint256 listingId) external view returns(uint256);

    function getMinNextBidAmount(uint256 listingId) external view returns (uint256);

    function placeBid(uint256 listingId) external payable;

    function getLatestBid(uint256 listingId) external view returns (Bid memory);

    function getBids(uint256 listingId) external view returns (Bid[] memory);

    function setBidSteps(BidStep[] memory _bidSteps) external;

    function getAuctionStartTime() external view returns (uint256);

    function changeAuctionStartTimestamp(uint256 _newTimestamp) external;

    function completeListing(uint256 listingId) external;

    function isListingClaimable(uint256 listingId) external view returns (bool);

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address);

    function emergencyWithdrawETH(address to, uint256 amount) external;

    function emergencyWithdrawERC20(address tokenContract, address to, uint256 amount) external;

    function returnTokenToProvider(uint256 listingId) external;

    function transferNFTFromAuction(
        address tokenContract,
        uint256 tokenId,
        address to
    ) external;
}

contract AccaAuction is IAccaAuction, ERC165, IERC1155Receiver, IERC721Receiver {

    using SafeTransferLib for address;
    
    struct AuctionStorage {
        string name;
        address owner;
        uint256 startTimestamp;
        uint256 auctionDuration;
        uint256 extraTimePeriod;
        address royaltyEngineAddress;

        uint256 _reentrancyStatus;

        // listingId => listingParameters
        mapping (uint256 => ListingDetails) listings;

        // store this as a separate mapping to make creating listings cheaper
        mapping (uint256 => bool) isListingClaimed;

        // listingId => bids
        mapping (uint256 => Bid[]) listingBids;

        // bidSteps
        BidStep[] bidSteps;
    }

    uint256 private constant ACCA_SHARE = 20;
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private constant ETH_SEND_GAS_STIPEND = 10_000;

    // keccak256(abi.encode(uint256(keccak256("acca.storage.auction")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AuctionStorageLocation = 0xf3d3c5373489466780afac49d56e4aa8e5c681cfad75e15483bd09008fc14900;

    function _getAucStorage() private pure returns (AuctionStorage storage _as) {
        assembly {
            _as.slot := AuctionStorageLocation
        }
    }

    /////// Initial Setup ///////

    function init(
        string calldata _name,
        address _owner,
        uint256 _startTimestamp,
        uint256 _auctionDuration,
        uint256 _extraTimePeriod,
        address _royaltyEngineAddress
    ) external {
        AuctionStorage storage _as = _getAucStorage();
        
        if(bytes(_as.name).length != 0) 
            revert AlreadyInitialized();
        
        _as._reentrancyStatus = NOT_ENTERED;        
        _as.name = _name;
        _as.owner = _owner;
        _as.royaltyEngineAddress = _royaltyEngineAddress;

        // set auc parameters
        _as.startTimestamp = _startTimestamp;
        _as.auctionDuration = _auctionDuration;
        _as.extraTimePeriod = _extraTimePeriod;
    }

    /////// Listings ///////

    function createListing(
        uint256 listingId,
        ListingDetails calldata listing
    ) public onlyOwner {
        _createListing(listingId, listing);
    }

    function createListings(
        uint256[] calldata listingIds,
        ListingDetails[] calldata listings
    ) public onlyOwner {
        if(listingIds.length != listings.length)
            revert ArraysSizesDoNotMatch();
        for(uint256 i; i < listingIds.length; ) {
            _createListing(
                listingIds[i],
                listings[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function _createListing(
        uint256 listingId,
        ListingDetails memory listing
    ) internal {
        AuctionStorage storage _as = _getAucStorage();
        _checkOwnedByThis(listing.contractAddres, listing.tokenId);
        if(listing.startPrice == 0)
            revert NoZeroStartPrice();
        if(_as.listings[listingId].contractAddres != address(0))
            revert ListingAlreadyExists(listingId);
        _as.listings[listingId] = listing;
        emit ListingAdded(
            listingId,
            listing.contractAddres,
            listing.tokenId,
            listing.tokenProvider,
            listing.startPrice,
            listing.reservePrice
        );
    }

    function replaceListing(
        uint256 listingId,
        ListingDetails memory listing
    ) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        if(_as.listings[listingId].contractAddres == address(0))
            revert NonExistentListing(listingId);
        if(isActive(listingId))
            revert ActiveListingNotReplaceable(listingId);
        _checkOwnedByThis(listing.contractAddres, listing.tokenId);
        _as.listings[listingId] = listing;
        emit ListingAdded(
            listingId,
            listing.contractAddres,
            listing.tokenId,
            listing.tokenProvider,
            listing.startPrice,
            listing.reservePrice
        );
    }

    function removeListing(uint256 listingId) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        if(_as.listings[listingId].contractAddres == address(0))
            revert NonExistentListing(listingId);
        if(isActive(listingId))
            revert ActiveListingNotRemoveable(listingId);
        delete _as.listings[listingId];
        delete _as.listingBids[listingId];
        delete _as.isListingClaimed[listingId];
    }

    function getListing(uint256 listingId) public view returns (ListingDetails memory) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.listings[listingId];
    }

    function isActive(uint256 listingId) public view returns(bool) {
        AuctionStorage storage _as = _getAucStorage();
        return (block.timestamp >= _as.startTimestamp) && 
            (block.timestamp <= 
                _as.startTimestamp +
                _as.auctionDuration +
                _as.listings[listingId].extraTime
            ) /*&&  !_as.isListingClaimed[listingId] */; //last condition removed for gas efficiency
    }

    function listingEndTime(uint256 listingId) public view returns(uint256) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.startTimestamp + _as.auctionDuration + _as.listings[listingId].extraTime;
    }

    /////// Bids ///////
    /**
     * @dev Place a bid on a listing
     * @param listingId id of the listing
     * @notice re entrancy guard was removed from here as re entrancy attempts are not possible
     * because of ETH_SEND_GAS_STIPEND size (see the appropriate test case)
     */
    function placeBid(uint256 listingId) public payable {
        AuctionStorage storage _as = _getAucStorage();
        if(!isActive(listingId))
            revert ListingNotActive(listingId);
        if (msg.value < getMinNextBidAmount(listingId)) 
            revert BidTooLow(listingId, msg.value);
        if (_as.listingBids[listingId].length != 0) {
            Bid storage prevBid = _as.listingBids[listingId][_as.listingBids[listingId].length-1];
            // send eth back to the prev bidder
            // do not revert if not successful
            if(prevBid.bidder.trySafeTransferETH(prevBid.bidAmount, ETH_SEND_GAS_STIPEND)) {
                prevBid.refunded = true;
            } else {
                emit EthTransferFailed(prevBid.bidder, prevBid.bidAmount);
            }
        }

        // record new bid
        _as.listingBids[listingId].push(Bid(msg.sender, false, msg.value));

        _checkAndAddExtraTime(listingId);
    }

    function getMinNextBidAmount(uint256 listingId) public view returns (uint256) {
        AuctionStorage storage _as = _getAucStorage();
        if(_as.listingBids[listingId].length == 0)
            return _as.listings[listingId].startPrice;
        
        uint256 curBidAmount = _as.listingBids[listingId][_as.listingBids[listingId].length-1].bidAmount;    
        uint256 step;
        step = _as.bidSteps[_as.bidSteps.length-1].stepSize;
        for (uint256 i; i < _as.bidSteps.length; ) {
            if (curBidAmount < _as.bidSteps[i].nextBidThreshold) {
                step = _as.bidSteps[i].stepSize;
                break;
            }
            unchecked {
                ++i;
            }
        }
        return curBidAmount + step;   
    }

    function getLatestBid(uint256 listingId) public view returns (Bid memory) {
        AuctionStorage storage _as = _getAucStorage();
        if (_as.listingBids[listingId].length == 0)
            revert NoBids(listingId);
        return _as.listingBids[listingId][_as.listingBids[listingId].length-1];
    }

    function getBids(uint256 listingId) public view returns (Bid[] memory) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.listingBids[listingId];
    }

    function setBidSteps(BidStep[] memory _bidSteps) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        // because copying struct[] from memory to storage not supported yet by codegen
        for(uint256 i; i < _bidSteps.length; ) {
            _as.bidSteps.push(_bidSteps[i]);
            unchecked {
                ++i;
            }
        }
    }

    /////// Send art to the winner ///////
    function completeListing(uint256 listingId) public {
        AuctionStorage storage _as = _getAucStorage();

        address tokenAddress = _as.listings[listingId].contractAddres;
        uint256 tokenId = _as.listings[listingId].tokenId;

        _checkOwnedByThis(tokenAddress, tokenId);
        
        if (!isListingClaimable(listingId))
            revert ListingNotClaimable(listingId);

        // length-1 is safe as we checked that there is at least one bid in isListingClaimable
        Bid memory winnerBid = _as.listingBids[listingId][_as.listingBids[listingId].length-1];

        // mark listing as claimed
        _as.isListingClaimed[listingId] = true;
        
        // distribute funds including royalties
        _distributeFundsIncludingRoyalties(listingId, winnerBid.bidAmount);

        // send token to claimer
        _detectErcAndTransferToken(
            tokenAddress,
            tokenId,
            winnerBid.bidder
        );
    }
    
    function isListingClaimable(uint256 listingId) public view returns (bool) {
        AuctionStorage storage _as = _getAucStorage();
        //active listings are not claimable
        if(isActive(listingId))
            return false;
        //if there's no bids, it is not claimable
        if (_as.listingBids[listingId].length == 0)
            return false;
        //check if listing is already claimed
        if (_as.isListingClaimed[listingId])
            return false;
        // check if reserve price is met
        if (_as.listingBids[listingId][_as.listingBids[listingId].length-1].bidAmount < _as.listings[listingId].reservePrice)
            return false;
        return true;
    }

    /////// Time Management ///////

    function getAuctionStartTime() public view returns (uint256) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.startTimestamp;
    }

    function changeAuctionStartTimestamp(uint256 _newTimestamp) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        if(_newTimestamp < block.timestamp)
            revert("Wrong Timestamp");
        if(block.timestamp > _as.startTimestamp)
            revert("AuctionHasStarted");
        _as.startTimestamp = _newTimestamp;
    }

    function startAuctionImmediately() public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        if(block.timestamp > _as.startTimestamp)
            revert("AuctionHasStarted");
        _as.startTimestamp = block.timestamp;
    }

    function getAuctionDuration() public view returns (uint256) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.auctionDuration;
    }

    function changeAuctionDuration(uint256 _newDuration) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        if(block.timestamp > _as.startTimestamp + _newDuration)
            revert("UseEndAuctionImmediatelyInstead");
        _as.auctionDuration = _newDuration;
    }

    function endAuctionImmediately() public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        if(block.timestamp > _as.startTimestamp + _as.auctionDuration)
            revert("AuctionHasEnded");
        _as.auctionDuration = block.timestamp - _as.startTimestamp - 1;
    }

    function getExtraTimePeriod() public view returns (uint256) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.extraTimePeriod;
    }

    function changeExtraTimePeriod(uint256 _newPeriod) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        _as.extraTimePeriod = _newPeriod;
    }

    function _checkAndAddExtraTime(uint256 listingId) internal {
        AuctionStorage storage _as = _getAucStorage();
        uint256 timeLeft = _as.startTimestamp + _as.auctionDuration + _as.listings[listingId].extraTime - block.timestamp;
        if (timeLeft < _as.extraTimePeriod) {
            _as.listings[listingId].extraTime += _as.extraTimePeriod - timeLeft;
        }
    }

    /////// Ownership ///////

    function transferOwnership(address _newOwner) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        address oldOwner = _as.owner;
        _as.owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    modifier onlyOwner() {
        AuctionStorage storage _as = _getAucStorage();
        if (_as.owner != msg.sender)
            revert NotOwner(msg.sender);
        _;
    }

    function owner() public view returns (address) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.owner;
    }

    /////// Administrative methods ///////

    function getRoyaltyEngineAddress() public view returns (address) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.royaltyEngineAddress;
    }

    function changeRoyaltyEngineAddress(address _newRoyaltyEngineAddress) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();
        _as.royaltyEngineAddress = _newRoyaltyEngineAddress;
    }

    // emergency withdraw ETH
    function emergencyWithdrawETH(address to, uint256 amount) public onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            emit EthTransferFailed(to, amount);
        }
    }

    // emergency withdraw ERC20
    function emergencyWithdrawERC20(address tokenContract, address to, uint256 amount) public onlyOwner {
        tokenContract.safeTransfer(to, amount);
    }

    // auction owner can return token to the tokenProvider 
    // if there were no bids or if the winner was not able to accept it
    function returnTokenToProvider(uint256 listingId) public onlyOwner {
        AuctionStorage storage _as = _getAucStorage();        
        // if listing is claimable, it cannot be returned
        if (isListingClaimable(listingId)) 
            revert ListingNotReturnable(listingId);  

        // if listing has been claimed already, it is not claimable
        // thus we need to check if token is still owned by this contract
        // it can be that listing has been marked as claimed, but the token is 
        // still owned by this contract because the winner was not able to accept it
        // so we can transfer it back to the provider
        _checkOwnedByThis(
            _as.listings[listingId].contractAddres,
            _as.listings[listingId].tokenId
        );

        // send token back to the tokenProvider
        _detectErcAndTransferToken(
            _as.listings[listingId].contractAddres,
            _as.listings[listingId].tokenId,
            _as.listings[listingId].tokenProvider
        );

        // clear listing
        delete _as.listings[listingId];
    }

    /**
    * @dev Transfer NFT from auction to the specified address
    * @dev !!! Permissioned method. Introducing it for the first auctions
    * just for the case somethig goes wrong and we need to return NFTs 
    * even without creating a listing etc
    * SHOULD be removed in the future to make auction permissionless
    * so the token can only be returned to the tokenProvider
    * @param tokenContract address of the token contract
    * @param tokenId id of the token
    * @param to address to transfer token to
    */
    function transferNFTFromAuction(
        address tokenContract,
        uint256 tokenId,
        address to
    ) public onlyOwner {
        _detectErcAndTransferToken(tokenContract, tokenId, to);
    }

    /////// Metadata ///////

    function name() public view returns (string memory) {
        AuctionStorage storage _as = _getAucStorage();
        return _as.name;
    }

    function getImplementation() public view returns (address _implementation)
    {
        assembly {
            _implementation := sload(address())
        }
    }

    /////// Internal Helpers ///////

    function _distributeFundsIncludingRoyalties(
        uint256 listingId,
        uint256 bidAmount
    ) internal {
        AuctionStorage storage _as = _getAucStorage();
        // send eth to the auction owner
        (bool success, ) = _as.owner.call{value: bidAmount * ACCA_SHARE / 100}("");
        if (!success) {
            emit EthTransferFailed(_as.owner, bidAmount * ACCA_SHARE / 100);
        }
    
        uint256 providerEarnings = bidAmount * (100 - ACCA_SHARE) / 100;
        
        try IRoyaltyEngineV1(_as.royaltyEngineAddress).getRoyaltyView(
            _as.listings[listingId].contractAddres,
            _as.listings[listingId].tokenId,
            providerEarnings
        ) returns (address payable[] memory recipients, uint256[] memory amounts) {
            //successfully received royalties info even empty
            uint256 totalRoyalties;
            for(uint256 i; i < recipients.length; ) {
                if(!address(recipients[i]).trySafeTransferETH(amounts[i], ETH_SEND_GAS_STIPEND)) {
                    emit EthTransferFailed(recipients[i], amounts[i]);
                }
                totalRoyalties = totalRoyalties + amounts[i];
                unchecked {
                    ++i;
                }
            }
            //send rest of eth to provider
            if(!_as.listings[listingId].tokenProvider.trySafeTransferETH(providerEarnings - totalRoyalties, ETH_SEND_GAS_STIPEND)) {
                emit EthTransferFailed(_as.listings[listingId].tokenProvider, providerEarnings - totalRoyalties);
            }
        } catch (bytes memory reason) {
            // Error getting royalties
            emit RoyaltiesRetrieveError(
                _as.listings[listingId].contractAddres, 
                _as.listings[listingId].tokenId, 
                providerEarnings, 
                reason
            );
            // Then transfer everything to provider
            if(!_as.listings[listingId].tokenProvider.trySafeTransferETH(providerEarnings, ETH_SEND_GAS_STIPEND)) {
                    emit EthTransferFailed(_as.listings[listingId].tokenProvider, providerEarnings);
            }
        } 
    }
    
    function _detectErcAndTransferToken(address tokenContract, uint256 tokenId, address to) internal {
        if (IERC165(tokenContract).supportsInterface(0x80ac58cd)) { 
            // ERC721
            try IERC721(tokenContract).safeTransferFrom(address(this), to, tokenId)
            {} catch(bytes memory reason) {
                emit NFTTransferError(tokenContract, tokenId, to, reason);
            }
        } else if (IERC165(tokenContract).supportsInterface(0x0e89341c)) {
            // ERC-1155
            try IERC1155(tokenContract).safeTransferFrom(address(this), to, tokenId, 1, "") 
            {} catch(bytes memory reason) {
                emit NFTTransferError(tokenContract, tokenId, to, reason);
            }
        } else
            revert NotSupportedToken(tokenContract);
    }

    function _checkOwnedByThis(address tokenContract, uint256 tokenId) internal view {
        if (IERC165(tokenContract).supportsInterface(0x80ac58cd)) // ERC721
            if (IERC721(tokenContract).ownerOf(tokenId) != address(this))
                revert NotOwnedByThis(tokenContract, tokenId);
            // otherwise proceed
        else if (IERC165(tokenContract).supportsInterface(0x0e89341c)) // ERC1155
            if (IERC1155(tokenContract).balanceOf(address(this), tokenId) == 0)
                revert NotOwnedByThis(tokenContract, tokenId);
            // otherwise proceed
        else
            revert NotSupportedToken(tokenContract);
    }

    /////// Token Receiver hooks /////// 

    //function onERC721Received
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if(data.length > 0) {
            (
                uint256 listingId, 
                uint256 startPrice, 
                uint256 reservePrice
            ) = abi.decode(data, (uint256, uint256, uint256));
            _createListing(listingId, ListingDetails(
                msg.sender,
                tokenId,
                from,
                startPrice,
                reservePrice,
                0
            ));
        }    
        return this.onERC721Received.selector;
    }

    //function onERC1155Received
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns(bytes4) {
        if(data.length > 0) {
            (
                uint256 listingId, 
                uint256 startPrice, 
                uint256 reservePrice
            ) = abi.decode(data, (uint256, uint256, uint256));
            _createListing(listingId, ListingDetails(
                msg.sender,
                id,
                from,
                startPrice,
                reservePrice,
                0
            ));
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns(bytes4) {
        return 0xffffffff; // do not support batch receiving
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

}