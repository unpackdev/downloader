// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function setApprovalForAll(address operator, bool _approved) external;
  function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function setApprovalForAll(address operator, bool approved) external;
  
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC2981 is IERC165Upgradeable {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract SatoshiMarketplaceV7 is Initializable,AccessControlUpgradeable {
    enum AssetType { UNKNOWN, ERC721, ERC1155 }
    enum ListingStatus { ON_HOLD, ON_SALE, IS_AUCTION}

    struct Listing {
        address contractAddress;
        AssetType assetType;
        ListingStatus status;
        uint numOfCopies;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 commission;
        bool isDropOfTheDay;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(address => mapping(uint256 => mapping(address => Listing))) private _listings;
    mapping(address => uint256) private _outstandingPayments;
    mapping(address=>bool) private _approveForRole;
    uint256 private _defaultCommission;
    uint256 private _defaultAuctionCommission;
    address private _commissionReceiver;
    bytes32 public constant DROP_OF_THE_DAY_CREATOR_ROLE=keccak256("DROP_OF_THE_DAY_CREATOR_ROLE");
    bool private _anyAddressCanCreateItem;
    bool private _askForRole;
    event PurchaseConfirmed(uint256 tokenId, address itemOwner, address buyer);
    event PaymentWithdrawn(uint256 amount);
    event TransferCommission(address indexed reciever, uint indexed tokenId, uint indexed value);
    event TransferRoyalty(address indexed receiver, uint indexed tokenId, uint indexed value);
    event HighestBidIncreased(uint256 tokenId,address itemOwner,address bidder,uint256 amount);
    event AuctionEnded(uint256 tokenId,address itemOwner,address winner,uint256 amount);

    function initialize() initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _defaultCommission = 250;
        _defaultAuctionCommission = 250;
        _commissionReceiver = msg.sender;
    }

    function commissionReceiver() external view returns (address) {
        return _commissionReceiver;
    }

    function setCommissionReceiver(address user) external returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "C1"
        );
        _commissionReceiver = user;

        return true;
    }

    function defaultCommission() external view returns (uint256) {
        return _defaultCommission;
    }

    function defaultAuctionCommission() external view returns (uint256) {
        return _defaultAuctionCommission;
    }

    function setDefaultCommission(uint256 commission) external returns (bool) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "C1"
        );
        require(commission <= 3000, "C2");
        _defaultCommission = commission;

        return true;
    }

    function setDefaultAuctionCommission(uint256 commission)
        external
        returns (bool)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "C1"
        );
        require(commission <= 3000, "C2");
        _defaultAuctionCommission = commission;

        return true;
    }

    function setListing(
        address contractAddress,
        AssetType assetType,
        uint256 tokenId,
        ListingStatus status,
        uint numOfCopies,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 dropOfTheDayCommission,
        bool isDropOfTheDay
    ) external {
        
        require(
            assetType == AssetType.ERC721 || assetType == AssetType.ERC1155,
            ""
        );

        if (assetType == AssetType.ERC721) {
            require(
                IERC721(contractAddress).balanceOf(msg.sender) > 0,
                "F1"
            );
            require(IERC721(contractAddress).isApprovedForAll(msg.sender,address(this)),"A1");
        } else if(assetType == AssetType.ERC1155) {
            require(
                IERC1155(contractAddress).balanceOf(msg.sender, tokenId) >= numOfCopies,
                "F1"
            );
            require(IERC1155(contractAddress).isApprovedForAll(msg.sender,address(this)),"A1");
        }

        if (status == ListingStatus.ON_HOLD) {
            require(
                _listings[contractAddress][tokenId][msg.sender].highestBidder == address(0),
                ""
            );

            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:0,
                price: 0,
                startTime: 0,
                endTime: 0,
                commission: 0,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (status == ListingStatus.ON_SALE) {
            require(
                _listings[contractAddress][tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "S2"
            );

            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:numOfCopies,
                price: price,
                startTime: 0,
                endTime: 0,
                commission: _defaultCommission,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if (status == ListingStatus.IS_AUCTION) {
            require(
                _listings[contractAddress][tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "S2"
            );
            require(
                block.timestamp < startTime && startTime < endTime,
                "S1"
            );

            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:numOfCopies,
                price: price,
                startTime: startTime,
                endTime: endTime,
                commission: _defaultAuctionCommission,
                isDropOfTheDay: false,
                highestBidder: address(0),
                highestBid: 0
            });
        } else if(isDropOfTheDay){
            //putting DOTD on auction
            require(
                hasRole(DROP_OF_THE_DAY_CREATOR_ROLE, msg.sender),
                "Marketplace: Caller is not a drop of the day creator"
            );
            require(
                _listings[contractAddress][tokenId][msg.sender].status == ListingStatus.ON_HOLD,
                "S2"
            );
            require(
                block.timestamp < startTime && startTime < endTime,
                "S1"
            );
            require(
                dropOfTheDayCommission <= 3000,
                "C2"
            );
            _listings[contractAddress][tokenId][msg.sender] = Listing({
                contractAddress: contractAddress,
                assetType: assetType,
                status: status,
                numOfCopies:numOfCopies,
                price: price,
                startTime: startTime,
                endTime: endTime,
                commission: dropOfTheDayCommission,
                isDropOfTheDay: isDropOfTheDay,
                highestBidder: address(0),
                highestBid: 0
            });
        }
    }

    function listingOf(address contractAddress, address account, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        require(
            account != address(0),
            ""
        );

        return _listings[contractAddress][tokenId][account];
    }

    function buy(uint256 tokenId, uint numOfCopies,address itemOwner, address contractAddress, bool isIERC2981)
        external
        payable
        returns (bool)
    {
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.ON_SALE,
            ""
        );

        if (_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC721) {
            require(
                IERC721(contractAddress).balanceOf(itemOwner) > 0,
                "S3"
            );
            require(msg.value == _listings[contractAddress][tokenId][itemOwner].price*1, "");
        } else if(_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC1155) {
            require(
                IERC1155(contractAddress).balanceOf(itemOwner, tokenId) >= _listings[contractAddress][tokenId][itemOwner].numOfCopies,
                " S3"
            );
            require(
                _listings[contractAddress][tokenId][itemOwner].numOfCopies>=numOfCopies,
                " S3"
            );
            require(msg.value == numOfCopies * _listings[contractAddress][tokenId][itemOwner].price, "");
        }
       
        if (_listings[contractAddress][tokenId][itemOwner].isDropOfTheDay) {
            require(
                block.timestamp >= _listings[contractAddress][tokenId][itemOwner].startTime &&
                block.timestamp <= _listings[contractAddress][tokenId][itemOwner].endTime,
                ""
            );
        }
        uint256 commision =
            (msg.value * _listings[contractAddress][tokenId][itemOwner].commission) / 10000;

        uint copiesLeft = 0;
        address ownerRoyaltyAddr;
        uint ownerRoyaltyAmount;
        
        if (_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC721) {
            IERC721(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId);
            if(isIERC2981) {
                (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, msg.value);
            }
            
        } else if(_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId, numOfCopies, "");
            if(isIERC2981) {
                (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, msg.value);
            }
            copiesLeft = _listings[contractAddress][tokenId][itemOwner].numOfCopies - numOfCopies;
        }

         _listings[contractAddress][tokenId][itemOwner] = Listing({
            contractAddress: copiesLeft >= 1 ? contractAddress : address(0),
            assetType: copiesLeft >= 1 ? _listings[contractAddress][tokenId][itemOwner].assetType : AssetType.UNKNOWN,
            status: copiesLeft >= 1 ? _listings[contractAddress][tokenId][itemOwner].status : ListingStatus.ON_HOLD,
            numOfCopies: copiesLeft >= 1 ? copiesLeft : 0,
            price: copiesLeft >= 1 ? _listings[contractAddress][tokenId][itemOwner].price : 0,
            startTime: 0,
            endTime: 0,
            commission: 0,
            isDropOfTheDay: false,
            highestBidder: address(0),
            highestBid: 0
        });
        emit PurchaseConfirmed(tokenId, itemOwner, msg.sender);
        _outstandingPayments[_commissionReceiver] += commision;
        _outstandingPayments[itemOwner] += (msg.value - commision);
        _outstandingPayments[ownerRoyaltyAddr] += ownerRoyaltyAmount;
        emit TransferCommission(_commissionReceiver, tokenId, commision);
        emit TransferRoyalty(ownerRoyaltyAddr, tokenId, ownerRoyaltyAmount);
        return true;
    }

    function withdrawPayment() external returns (bool) {
        uint256 amount = _outstandingPayments[msg.sender];
        if (amount > 0) {
            _outstandingPayments[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                _outstandingPayments[msg.sender] = amount;
                return false;
            }
            emit PaymentWithdrawn(amount);
        }
        return true;
    }

    function outstandingPayment(address user) external view returns (uint256) {
        return _outstandingPayments[user];
    }

    //Auction
    function bid(address contractAddress, uint256 tokenId, address itemOwner) external payable {
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.IS_AUCTION,
            ""
        );
        require(
            block.timestamp <= _listings[contractAddress][tokenId][itemOwner].endTime &&
                block.timestamp >= _listings[contractAddress][tokenId][itemOwner].startTime,
            ""
        );
        require(
            msg.value > _listings[contractAddress][tokenId][itemOwner].highestBid,
            ""
        );

        if (_listings[contractAddress][tokenId][itemOwner].highestBid != 0) {
            _outstandingPayments[
                _listings[contractAddress][tokenId][itemOwner].highestBidder
            ] += _listings[contractAddress][tokenId][itemOwner].highestBid;
        }
        _listings[contractAddress][tokenId][itemOwner].highestBidder = msg.sender;
        _listings[contractAddress][tokenId][itemOwner].highestBid = msg.value;
        emit HighestBidIncreased(tokenId, itemOwner, msg.sender, msg.value);
    }

    function auctionEnd(address contractAddress, uint256 tokenId, address itemOwner, bool isIERC2981) external {
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.IS_AUCTION,
            ""
        );
        require(
            block.timestamp > _listings[contractAddress][tokenId][itemOwner].endTime,
            ""
        );

        uint256 commision =
            (_listings[contractAddress][tokenId][itemOwner].highestBid *
                _listings[contractAddress][tokenId][itemOwner].commission) / 10000;

        address ownerRoyaltyAddr;
        uint ownerRoyaltyAmount;
        if (_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC721) {
            IERC721(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId);
            if(isIERC2981){
                (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, _listings[contractAddress][tokenId][itemOwner].highestBid);
            }
        } else if(_listings[contractAddress][tokenId][itemOwner].assetType == AssetType.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(itemOwner, msg.sender, tokenId, 1, "");
            if(isIERC2981){
                (ownerRoyaltyAddr,ownerRoyaltyAmount) = IERC2981(contractAddress).royaltyInfo(tokenId, _listings[contractAddress][tokenId][itemOwner].highestBid);
            }
        }
        _listings[contractAddress][tokenId][itemOwner] = Listing({
            contractAddress: address(0),
            assetType: AssetType.UNKNOWN,
            status: ListingStatus.ON_HOLD,
            numOfCopies:_listings[contractAddress][tokenId][itemOwner].numOfCopies,
            price: 0,
            startTime: 0,
            endTime: 0,
            commission: 0,
            isDropOfTheDay: false,
            highestBidder: _listings[contractAddress][tokenId][itemOwner].highestBidder,
            highestBid: _listings[contractAddress][tokenId][itemOwner].highestBid
        });
        emit AuctionEnded(
            tokenId,
            itemOwner,
            _listings[contractAddress][tokenId][itemOwner].highestBidder,
            _listings[contractAddress][tokenId][itemOwner].highestBid
        );

        _outstandingPayments[itemOwner] += commision;
        _outstandingPayments[itemOwner] += (_listings[contractAddress][tokenId][itemOwner].highestBid - commision);
        _outstandingPayments[ownerRoyaltyAddr] += ownerRoyaltyAmount;
        emit TransferCommission(_commissionReceiver, tokenId, commision);
        emit TransferRoyalty(ownerRoyaltyAddr, tokenId, ownerRoyaltyAmount);
    }

    function setDropOfTheDayAuctionEndTime(uint256 tokenId, address contractAddress,address itemOwner,uint256 newEndTime) external{
        require(
            hasRole(DROP_OF_THE_DAY_CREATOR_ROLE, msg.sender),
            ""
        );
        require(
            _listings[contractAddress][tokenId][itemOwner].status == ListingStatus.IS_AUCTION,
            ""
        );
        require(
            _listings[contractAddress][tokenId][itemOwner].isDropOfTheDay,
            ""
        );
        require(
            _listings[contractAddress][tokenId][itemOwner].endTime < newEndTime,
            ""
        );
        _listings[contractAddress][tokenId][itemOwner].endTime = newEndTime;
    }

    /** transfer ADMIN ROLE functions*/

    //admin call this function first to approve the addr
    function approveAddressForRole(address _receipent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"C1");
        _approveForRole[_receipent] = true;
    }
    //approved address will call this function and ask for permission
    function askForRole() external {
        require(_approveForRole[msg.sender], "");
        _askForRole = true;
    }
    //admin will call this function and assing the ADMIN role
    function transferRoleOwnership(address _receipent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),"C1");
        require(_askForRole,"");
        _approveForRole[_receipent] = false;
        _askForRole = false;
        super.grantRole(DEFAULT_ADMIN_ROLE, _receipent);
        renounceRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    /**batch listing function */
    function setBatchListing(
        address[] memory contractAddress,
        AssetType assetType,
        uint256[] memory tokenId,
        ListingStatus status,
        uint[] memory numOfCopies,
        uint256[] memory price,
        uint256[] memory startTime,
        uint256[] memory endTime
    ) external {
        
        require(
            assetType == AssetType.ERC721 || assetType == AssetType.ERC1155,
            ""
        );
        require(contractAddress.length == tokenId.length,"");
        require(contractAddress.length == numOfCopies.length,"");
        require(contractAddress.length == price.length,"");
        require(contractAddress.length == startTime.length,"");
        require(contractAddress.length == endTime.length,"");
        require(startTime.length == endTime.length,"");

        if (assetType == AssetType.ERC721) {
            for(uint16 i=0;i<contractAddress.length;i++){
                require(
                    IERC721(contractAddress[i]).balanceOf(msg.sender) > 0,
                    "F1"
                );
                require(
                    IERC721(contractAddress[i]).isApprovedForAll(msg.sender,address(this)),
                    "A1"
                );
            }
            
        } else if(assetType == AssetType.ERC1155) {
            for(uint16 i=0;i<contractAddress.length;i++){
                require(IERC1155(contractAddress[i]).balanceOf(msg.sender, tokenId[i]) >= 1,
                "F1"
                );
                require(IERC1155(contractAddress[i]).isApprovedForAll(msg.sender,address(this)),"A1");
            }
            
        }

        if (status == ListingStatus.ON_HOLD) {
            for(uint16 i=0;i<contractAddress.length;i++){
                require(
                _listings[contractAddress[i]][tokenId[i]][msg.sender].highestBidder == address(0),
                ""
            );

                _listings[contractAddress[i]][tokenId[i]][msg.sender] = Listing({
                    contractAddress: contractAddress[i],
                    assetType: assetType,
                    status: status,
                    numOfCopies:0,
                    price: 0,
                    startTime: 0,
                    endTime: 0,
                    commission: 0,
                    isDropOfTheDay: false,
                    highestBidder: address(0),
                    highestBid: 0
                });

            }
            
        } else if (status == ListingStatus.ON_SALE) {
            for(uint16 i=0;i<contractAddress.length;i++){
                require(
                    _listings[contractAddress[i]][tokenId[i]][msg.sender].status == ListingStatus.ON_HOLD,
                    "S2"
                );

                _listings[contractAddress[i]][tokenId[i]][msg.sender] = Listing({
                    contractAddress: contractAddress[i],
                    assetType: assetType,
                    status: status,
                    numOfCopies:numOfCopies[i],
                    price: price[i],
                    startTime: 0,
                    endTime: 0,
                    commission: _defaultCommission,
                    isDropOfTheDay: false,
                    highestBidder: address(0),
                    highestBid: 0
                });
            }
            
        } else if (status == ListingStatus.IS_AUCTION) {
            for(uint16 i=0; i<startTime.length;i++){
                require(
                    block.timestamp < startTime[i] && startTime[i] < endTime[i],
                    "S1"
                );
            }
            for(uint16 i=0;i<contractAddress.length;i++){
                require(
                    _listings[contractAddress[i]][tokenId[i]][msg.sender].status == ListingStatus.ON_HOLD,
                    "S2"
                );
            
                _listings[contractAddress[i]][tokenId[i]][msg.sender] = Listing({
                    contractAddress: contractAddress[i],
                    assetType: assetType,
                    status: status,
                    numOfCopies:numOfCopies[i],
                    price: price[i],
                    startTime: startTime[i],
                    endTime: endTime[i],
                    commission: _defaultAuctionCommission,
                    isDropOfTheDay: false,
                    highestBidder: address(0),
                    highestBid: 0
                });
            }
        } 
    }
}