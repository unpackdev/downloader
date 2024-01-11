// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0 <0.9.0;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./PermissionManagement.sol";
import "./MonumentArtifacts.sol";
import "./Payable.sol";

/// @title Monument Marketplace Contract
/// @author kumareth@monument.app
/// @notice In Monument.app context, this contract becomes an Automated Market Maker for the Artifacts minted in the Monument Metaverse
contract MonumentMarketplace is Payable, ReentrancyGuard {
  constructor (
    address _permissionManagementContractAddress,
    address payable _allowedNFTContractAddress
  )
  Payable(_permissionManagementContractAddress)
  payable
  {
    // The NFT Contract
    require(_allowedNFTContractAddress != address(0));
    allowedNFTContractAddress = _allowedNFTContractAddress;
    allowedNFTContract = MonumentArtifacts(_allowedNFTContractAddress);

    // create a genesis fake auction that expires quickly for avoiding out of bounds error
    _enableAuction(10 ** 18, 0, 0);

    // create a genesis $0 fake internal order that expires in 60 seconds for avoiding blank zero mapping conflict
    _placeOrder(0, 60);
    orders[0].tokenId = 10 ** 18;
    orders[0].price = 0;
  }




  // Credits
  mapping(address => uint256) public credits;

  /// @notice Used to withdraw credits - Pull over Push Pattern
  function withdraw (
    uint256 _amount,
    address _to
  ) nonReentrant external {
      require(_amount <= credits[_to], "insufficient balance");
      require(
        msg.sender == _to ||
        permissionManagement.moderators(msg.sender) == true,
        "unauthorised withdrawal"
      );

      credits[_to] = credits[_to] - _amount;

      (bool success, ) = payable(_to).call{value: _amount}("");
      require(success, "withdrawal failed");

      emit Withdrew (msg.sender, _to, _amount, block.timestamp);
  }



  // Auction IDs Counter
  using Counters for Counters.Counter;
  Counters.Counter public totalAuctions;




  // Manage what NFTs can be bought and sold in the marketplace
  address public allowedNFTContractAddress;
  MonumentArtifacts allowedNFTContract;
  
  function changeAllowedNFTContract(address payable _nftContractAddress) 
    external
    returns(address)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    allowedNFTContractAddress = _nftContractAddress;
    allowedNFTContract = MonumentArtifacts(_nftContractAddress);
    return _nftContractAddress;
  }




  // Taxes
  uint256 public taxOnEverySaleInPermyriad;

  function changeTaxOnEverySaleInPermyriad(uint256 _taxOnEverySaleInPermyriad) 
    external
    returns(uint256)
  {
    permissionManagement.adminOnlyMethod(msg.sender);
    require(_taxOnEverySaleInPermyriad <= 10000, "permyriad value out of bounds");
    taxOnEverySaleInPermyriad = _taxOnEverySaleInPermyriad;
    return _taxOnEverySaleInPermyriad;
  }




  // Events
  event EnabledAuction(
    uint256 indexed id,
    uint256 indexed _tokenId,
    uint256 _basePrice,
    uint256 _auctionExpiryTime,
    address indexed _enabledBy,
    uint256 _timestamp
  );
  event EndedAuction(
    uint256 indexed id,
    uint256 indexed _tokenId,
    address indexed _endedBy,
    uint256 _timestamp
  );
  event ListedEditions(
    uint256 indexed _artifactId,
    uint256 _editions,
    uint256 _price,
    uint256 _timestamp,
    address indexed _listedBy
  );
  event UnlistedEditions(
    uint256 indexed _artifactId,
    uint256 _timestamp,
    address indexed _unlistedBy
  );
  event EnabledAutoSell(
    uint256 indexed _tokenId,
    uint256 _price,
    address indexed _enabledBy,
    uint256 _timestamp
  );
  event DisabledAutoSell(
    uint256 indexed _tokenId,
    address indexed _disabledBy,
    uint256 _timestamp
  );
  event OrderPlaced(
    uint256 indexed id,
    address indexed buyer,
    uint256 indexed tokenId,
    uint256 price,
    uint256 createdAt,
    uint256 expiresAt
  );
  event OrderExecuted(
    uint256 indexed id,
    uint256 indexed tokenId,
    uint256 timestamp,
    address executedBy,
    address indexed priorOwner
  );
  event OrderCancelled(
    uint256 indexed id,
    uint256 indexed tokenId,
    uint256 timestamp,
    address indexed cancelledBy
  );
  event EditionsBought(
    uint256 indexed artifactId,
    address indexed buyer,
    uint256 editions,
    uint256 pricePerEdition,
    uint256 timestamp
  );
  event Withdrew (
    address indexed actionedBy,
    address indexed to,
    uint256 amount,
    uint256 timestamp
  );




  // Enable/Disable Autosell, and Auction Management

  struct Auction {
    uint256 id;
    uint256 tokenId;
    uint256 basePrice;
    uint256 highestBidOrderId;
    uint256 startTime;
    uint256 expiryTime;
  }
  Auction[] public auctions;

  mapping(uint256 => uint256) public getTokenPrice;
  mapping(uint256 => bool) public isTokenAutoSellEnabled;

  mapping(uint256 => uint256) public getEditionsPrice;
  mapping(uint256 => uint256) public howManyEditionsAutoSellEnabled;

  mapping(uint256 => bool) public isTokenAuctionEnabled;
  mapping(uint256 => uint256) public getLatestAuctionIDByTokenID;
  mapping(uint256 => uint256[]) public getAuctionIDsByTokenID;

  /// @notice Allows Artifact Owner to List the Artifact Edtions on the Marketplace for Mass Sale
  /// @param _artifactId ID of the Artifact to List on the Market with Selling Auto-Enabled
  /// @param _editions Number of remaining editions of the artifact you wish to list
  /// @param _pricePerEdition At what Price in Wei, if an Order recevied, should be automatically executed?
  function listEditions(
    uint256 _artifactId,
    uint256 _editions,
    uint256 _pricePerEdition
  ) nonReentrant external returns (uint256, uint256) {
    require(
      allowedNFTContract.getArtifactAuthor(_artifactId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "unauthorized listEditions"
    );

    (
      uint256 totalSupply, 
      uint256 currentSupply,
    ) = allowedNFTContract.getArtifactSupply(_artifactId);

    require(
      _editions <= totalSupply - currentSupply, 
      "supply out of bounds"
    );

    howManyEditionsAutoSellEnabled[_artifactId] = _editions;
    getEditionsPrice[_artifactId] = _pricePerEdition;

    emit ListedEditions(
      _artifactId,
      _editions,
      _pricePerEdition,
      block.timestamp,
      msg.sender
    );

    return (_artifactId, _pricePerEdition);
  }

  /// @notice Allows Artifact Owner to Unlist the Artifact Edtions on the Marketplace for Mass Sale
  /// @param _artifactId ID of the Artifact to UnList from the Marketplace
  function unlistEditions(
    uint256 _artifactId
  ) nonReentrant external returns (uint256) {
    require(
      allowedNFTContract.getArtifactAuthor(_artifactId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "unauthorized unlistEditions"
    );

    howManyEditionsAutoSellEnabled[_artifactId] = 0;

    emit UnlistedEditions(
      _artifactId,
      block.timestamp,
      msg.sender
    );

    return _artifactId;
  }

  /// @notice Allows Token Owner to List the Tokens on the Marketplace with Auction Enabled
  /// @param _tokenIds IDs of the Tokens to List on the Market with Selling Auto-Enabled
  /// @param _basePrice Minimum Price one must put to Bid in the Auction.
  /// @param _auctionExpiresIn Set an End Time for the Auction
  function enableAuction(
    uint256[] memory _tokenIds,
    uint256 _basePrice,
    uint256 _auctionExpiresIn
  ) nonReentrant external returns(uint256[] memory, uint256) {
    uint256 tokensLength = _tokenIds.length;
    for (uint256 i = 0; i < tokensLength; i++) {
      uint256 _tokenId = _tokenIds[i];

      require(
        (
          allowedNFTContract.ownerOf(_tokenId) == msg.sender ||
          allowedNFTContract.getApproved(_tokenId) == msg.sender ||
          permissionManagement.moderators(msg.sender) == true
        ) && allowedNFTContract.exists(_tokenId) == true, 
        "unauthorized enableAuction"
      );

      // if auction is already on, err
      require(isTokenAuctionEnabled[_tokenId] != true, "token already in auction");

      _enableAuction(
        _tokenId,
        _basePrice,
        _auctionExpiresIn
      );
    }

    return (_tokenIds, _basePrice);
  }

  function _enableAuction(
    uint256 _tokenId,
    uint256 _basePrice,
    uint256 _auctionExpiresIn
  ) private returns(uint256, uint256, uint256) {
    getTokenPrice[_tokenId] = _basePrice;
    isTokenAutoSellEnabled[_tokenId] = false;

    uint256 newAuctionId = totalAuctions.current();
    totalAuctions.increment();

    isTokenAuctionEnabled[_tokenId] = true;
    auctions.push(
      Auction(
        newAuctionId,
        _tokenId,
        _basePrice,
        0,
        block.timestamp,
        block.timestamp + _auctionExpiresIn
      )
    );
    getLatestAuctionIDByTokenID[_tokenId] = newAuctionId;
    getAuctionIDsByTokenID[_tokenId].push(newAuctionId);

    emit EnabledAuction(
      newAuctionId,
      _tokenId,
      _basePrice,
      block.timestamp + _auctionExpiresIn,
      msg.sender,
      block.timestamp
    );

    return (_tokenId, _basePrice, _auctionExpiresIn);
  }

  /// @notice Allows Token Owner or the Auction Winner to Execute the Auction of their Token
  /// @param _tokenId ID of the Token whose Auction to end
  function executeAuction(
    uint256 _tokenId
  ) nonReentrant external returns(uint256, uint256) {
    // cant execute an auction that never started
    require(isTokenAuctionEnabled[_tokenId] == true && allowedNFTContract.exists(_tokenId) == true, "token not auctioned");

    // if auction didn't end by time yet
    if (block.timestamp <= auctions[getLatestAuctionIDByTokenID[_tokenId]].expiryTime) {
      // allow only moderators or owner or approved to execute the auction
      require(
        permissionManagement.moderators(msg.sender) == true || 
        allowedNFTContract.ownerOf(_tokenId) == msg.sender || 
        allowedNFTContract.getApproved(_tokenId) == msg.sender, 
        "you cant execute this auction just yet"
      );

    // if auction expired/ended
    } else {
      // allow only auction winner or moderators or owner or approved to execute the auction
      require(
        permissionManagement.moderators(msg.sender) == true || 
        allowedNFTContract.ownerOf(_tokenId) == msg.sender || 
        allowedNFTContract.getApproved(_tokenId) == msg.sender ||
        orders[auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId].buyer == msg.sender,
        "you cant execute this auction"
      );
    }

    return _executeAuction(_tokenId);
  }

  function _executeAuction(
    uint256 _tokenId
  ) private returns(uint256, uint256) {
    // if there is a valid highest bid
    uint256 _orderId;
    if (auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId != 0) {
        // check if auction winner funded more than or equal to the base price
        if (
          orders[
            auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId
          ].price
            >=
          auctions[getLatestAuctionIDByTokenID[_tokenId]].basePrice
        ) {
          // give the token to the auction winner and carry the transaction
          _orderId = _executeOrder(auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId);

          allowedNFTContract.marketTransfer(
            allowedNFTContract.ownerOf(_tokenId),
            orders[auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId].buyer, 
            _tokenId
          );
        }
    }

    isTokenAutoSellEnabled[_tokenId] = false;
    isTokenAuctionEnabled[_tokenId] = false;

    emit EndedAuction(
      getLatestAuctionIDByTokenID[_tokenId],
      _tokenId,
      msg.sender,
      block.timestamp
    );
    
    return (_tokenId, _orderId);
  }

  /// @notice Allows Token Owner to List their Tokens on the Marketplace with Automated Selling
  /// @param _tokenIds ID of the Token to List on the Market with Selling Auto-Enabled
  /// @param _pricePerToken At what Price in Wei, if an Order recevied, should be automatically executed?
  function enableAutoSell(
    uint256[] memory _tokenIds,
    uint256 _pricePerToken
  ) nonReentrant external returns(uint256[] memory, uint256) {
    uint256 tokensLength = _tokenIds.length;
    for (uint256 i = 0; i < tokensLength; i++) {
      uint256 _tokenId = _tokenIds[i];

      require(allowedNFTContract.exists(_tokenId) == true, "invalid tokenId");

      require(
        allowedNFTContract.ownerOf(_tokenId) == msg.sender ||
        allowedNFTContract.getApproved(_tokenId) == msg.sender ||
        permissionManagement.moderators(msg.sender) == true, 
        "unauthorized enableAutoSell"
      );

      // if auction is already on, it must be executed first
      require(isTokenAuctionEnabled[_tokenId] != true, "token already in auction");

      getTokenPrice[_tokenId] = _pricePerToken;
      isTokenAutoSellEnabled[_tokenId] = true;
      isTokenAuctionEnabled[_tokenId] = false;

      emit EnabledAutoSell(
        _tokenId,
        _pricePerToken,
        msg.sender,
        block.timestamp
      );
    }

    return (_tokenIds, _pricePerToken);
  }

  /// @notice Allows Token Owner to Disable Auto Selling of their Tokens
  /// @param _tokenIds IDs of the Tokens to List on the Market with Auto-Selling Disabled
  function disableAutoSell(
    uint256[] memory _tokenIds
  ) nonReentrant external returns(uint256[] memory) {
    uint256 tokensLength = _tokenIds.length;
    for (uint256 i = 0; i < tokensLength; i++) {
      uint256 _tokenId = _tokenIds[i];

      require(
        allowedNFTContract.ownerOf(_tokenId) == msg.sender ||
        allowedNFTContract.getApproved(_tokenId) == msg.sender ||
        permissionManagement.moderators(msg.sender) == true, 
        "unauthorized disableAutoSell"
      );

      // if auction is already on, it must be executed first
      require(isTokenAuctionEnabled[_tokenId] != true, "token is in an auction");

      _disableAutoSell(_tokenId);
    }

    return _tokenIds;
  }

  function _disableAutoSell(
    uint256 _tokenId
  ) internal returns(uint256) {
    isTokenAutoSellEnabled[_tokenId] = false;
    isTokenAuctionEnabled[_tokenId] = false;

    emit DisabledAutoSell(
      _tokenId,
      msg.sender,
      block.timestamp
    );

    return _tokenId;
  }




  // Orders Management

  struct Order {
    uint256 id;
    address payable buyer;
    uint256 tokenId;
    uint256 price;
    uint256 createdAt;
    uint256 expiresAt;
    address payable placedBy;
    bool isDuringAuction;
  }

  enum OrderStatus { INVALID, PLACED, EXECUTED, CANCELLED }

  Order[] public orders;

  // tokenId to orderId[] mapping
  mapping (uint256 => uint256[]) public getOrderIDsByTokenID;

  // orderId to OrderStatus mapping
  mapping (uint256 => OrderStatus) public getOrderStatus;




  // Internal Functions relating to Order Management

  function _placeOrder(
    uint256 _tokenId,
    uint256 _expireInSeconds
  ) private returns(uint256) {
    require(allowedNFTContract.ownerOf(_tokenId) != msg.sender, "not on your own token");

    uint256 _orderId = orders.length;

    Order memory _order = Order({
      id: _orderId,
      buyer: payable(msg.sender),
      tokenId: _tokenId,
      price: msg.value,
      createdAt: block.timestamp,
      expiresAt: block.timestamp + _expireInSeconds,
      placedBy: payable(msg.sender),
      isDuringAuction: isTokenAuctionEnabled[_tokenId]
    });

    orders.push(_order);
    getOrderIDsByTokenID[_tokenId].push(_order.id);
    getOrderStatus[_orderId] = OrderStatus.PLACED;

    if (msg.value > orders[auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId].price) {
      auctions[getLatestAuctionIDByTokenID[_tokenId]].highestBidOrderId = _orderId;
    }

    emit OrderPlaced(
      _order.id,
      _order.buyer,
      _order.tokenId,
      _order.price,
      _order.createdAt,
      _order.expiresAt
    );

    return _orderId;
  }

  function _placeOffer(
    uint256 _tokenId,
    uint256 _expireInSeconds,
    address _buyer,
    uint256 _price
  ) private returns(uint256) {
    require(allowedNFTContract.exists(_tokenId) == true, "invalid tokenId");
    require(
      allowedNFTContract.ownerOf(_tokenId) == msg.sender || 
      allowedNFTContract.getApproved(_tokenId) == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "you cant offer this token"
    );
    require(_buyer != msg.sender, "cant offer yourself");

    uint256 _orderId = orders.length;

    Order memory _order = Order({
      id: _orderId,
      buyer: payable(_buyer),
      tokenId: _tokenId,
      price: _price,
      createdAt: block.timestamp,
      expiresAt: block.timestamp + _expireInSeconds,
      placedBy: payable(msg.sender),
      isDuringAuction: isTokenAuctionEnabled[_tokenId]
    });

    orders.push(_order);
    getOrderIDsByTokenID[_tokenId].push(_order.id);
    getOrderStatus[_orderId] = OrderStatus.PLACED;

    emit OrderPlaced(
      _order.id,
      _order.buyer,
      _order.tokenId,
      _order.price,
      _order.createdAt,
      _order.expiresAt
    );

    return _orderId;
  }

  function _executeOrder(
    uint256 _orderId
  ) private returns(uint256) {
    require(getOrderStatus[_orderId] != OrderStatus.CANCELLED, "order already cancelled");
    require(getOrderStatus[_orderId] != OrderStatus.EXECUTED, "order already executed");

    // order that is the current highest bid made during an auction cannot expire
    require(
      block.timestamp <= orders[_orderId].expiresAt || 
      (
        orders[_orderId].isDuringAuction == true && 
        auctions[getLatestAuctionIDByTokenID[orders[_orderId].tokenId]].highestBidOrderId == _orderId
      ), 
      "order expired"
    );

    require(orders[_orderId].price <= msg.value || orders[_orderId].price <= getBalance(), "insufficient contract balance");

    if (orders[_orderId].price != 0) {
      // calculate and split royalty
      (
        address royaltyReceiver, 
        uint256 royaltyAmount
      ) = allowedNFTContract.royaltyInfo(
        orders[_orderId].tokenId,
        orders[_orderId].price
      );

      if (royaltyAmount != 0 && royaltyReceiver != address(0)) {
        // pay the Splits contract
        (bool success1, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
        require(success1, "transfer to splits failed");
      }

      uint256 beneficiaryPay = (orders[_orderId].price - royaltyAmount) * taxOnEverySaleInPermyriad / 10000;

      // pay taxes
      (bool success2, ) = permissionManagement.beneficiary().call{value: beneficiaryPay}("");
      require(success2, "transfer to beneficiary failed");

      // pay the owner
      credits[allowedNFTContract.ownerOf(orders[_orderId].tokenId)] = credits[allowedNFTContract.ownerOf(orders[_orderId].tokenId)] + orders[_orderId].price - beneficiaryPay - royaltyAmount;
    }

    getOrderStatus[_orderId] = OrderStatus.EXECUTED;

    _disableAutoSell(orders[_orderId].tokenId);

    emit OrderExecuted(_orderId, orders[_orderId].tokenId, block.timestamp, msg.sender, allowedNFTContract.ownerOf(orders[_orderId].tokenId));

    return _orderId;
  }

  function _cancelOrder(
    uint256 _orderId
  ) private returns(uint256) {
    require(getOrderStatus[_orderId] == OrderStatus.PLACED, "never placed");

    getOrderStatus[_orderId] = OrderStatus.CANCELLED;

    if (orders[_orderId].price != 0 && orders[_orderId].placedBy == orders[_orderId].buyer) {
      credits[orders[_orderId].buyer] = credits[orders[_orderId].buyer] + orders[_orderId].price;
    }

    emit OrderCancelled(_orderId, orders[_orderId].tokenId, block.timestamp, msg.sender);

    return _orderId;
  }




  // Public Marketplace Functions

  /// @notice Buys Editions of an Artifact
  /// @param _artifactId Artifact ID to whose editions you wanna place an Order On.
  /// @param _editions Number of Editions to buy.
  function buyEditions(
    uint256 _artifactId,
    uint256 _editions
  ) nonReentrant external payable returns(uint256) {
    if (_editions == 0) {
      _editions = 1;
    }

    require(howManyEditionsAutoSellEnabled[_artifactId] >= _editions, "autosale editions exhausted");

    require(msg.value >= getEditionsPrice[_artifactId] * _editions, "insufficient amount");

    allowedNFTContract.mintEditions(_artifactId, _editions, msg.sender);

    howManyEditionsAutoSellEnabled[_artifactId] = howManyEditionsAutoSellEnabled[_artifactId] - _editions;

    if (msg.value > 0) {
      uint256 totalPayable = msg.value;

      // calculate and split royalty
      (
        address royaltyReceiver, 
        uint256 royaltyAmount
      ) = allowedNFTContract.royaltyInfoByArtifactId(
          _artifactId,
          getEditionsPrice[_artifactId] * _editions
        );

      if (royaltyAmount != 0 && royaltyReceiver != address(0)) {
        // pay the Splits contract
        (bool success1, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
        require(success1, "transfer to splits failed");
      }

      uint256 beneficiaryPay = (totalPayable - royaltyAmount) * taxOnEverySaleInPermyriad / 10000;

      // pay taxes
      (bool success2, ) = permissionManagement.beneficiary().call{value: beneficiaryPay}("");
      require(success2, "transfer to beneficiary failed");

      // pay the owner
      credits[allowedNFTContract.getArtifactAuthor(_artifactId)] = credits[allowedNFTContract.getArtifactAuthor(_artifactId)] + totalPayable - beneficiaryPay - royaltyAmount;
    }

    emit EditionsBought(
      _artifactId,
      msg.sender,
      _editions,
      getEditionsPrice[_artifactId],
      block.timestamp
    );

    return _artifactId;
  }

  /// @notice Places Order on a Token
  /// @dev Creates an Order
  /// @param _tokenId Token ID to place an Order On.
  /// @param _expireInSeconds Seconds you want the Order to Expire in.
  function placeOrder(
    uint256 _tokenId,
    uint256 _expireInSeconds
  ) nonReentrant external payable returns(uint256) {
    require(_expireInSeconds >= 60, "not within 60 seconds");
    require(msg.value >= 1, "a non-zero value must be paid");

    uint256 _orderId = _placeOrder(_tokenId, _expireInSeconds);

    // check if token is sellable
    address payable tokenOwner = payable(allowedNFTContract.ownerOf(_tokenId));

    // if sellable, buy
    if (isTokenAutoSellEnabled[_tokenId] == true) {
      // if free, complete transaction
      if (getTokenPrice[_tokenId] == 0) {
        _executeOrder(_orderId);
        allowedNFTContract.marketTransfer(tokenOwner, msg.sender, _tokenId);
        return _orderId;
      }

      // check if offerPrice matches getTokenPrice, if yes, complete transaction.
      if (msg.value >= getTokenPrice[_tokenId]) {
        _executeOrder(_orderId);
        allowedNFTContract.marketTransfer(tokenOwner, msg.sender, _tokenId);
        return _orderId;
      }
    }

    return _orderId;
  }

  /// @notice For Token Owner to Offer a Token to someone
  /// @dev Creates an Offer Order
  /// @param _tokenId Token ID to place an Order On.
  /// @param _expireInSeconds Seconds you want the Order to Expire in.
  /// @param _buyer Prospective Buyer Address
  /// @param _price Price at which the Token Owner aims to sell the Token to the Buyer
  function placeOffer(
    uint256 _tokenId,
    uint256 _expireInSeconds,
    address _buyer,
    uint256 _price
  ) nonReentrant external returns(uint256) {
    require(_expireInSeconds >= 60, "not within 60 seconds");

    // if auction is on, token owner cant place offers
    require(isTokenAuctionEnabled[_tokenId] != true, "cant offer tokens during auction");

    uint256 _orderId = _placeOffer(_tokenId, _expireInSeconds, _buyer, _price);

    return _orderId;
  }

  /// @notice For Token Owner to Approve an Order, or for Buyer to Accept an Offer
  /// @dev Executes an Order on Valid Acceptance
  /// @param _orderId ID of the Order to Accept
  function acceptOffer(
    uint256 _orderId
  ) nonReentrant external payable returns(uint256) {
    Order memory _order = orders[_orderId];
    address tokenOwner = allowedNFTContract.ownerOf(_order.tokenId);
    address tokenApprovedAddress = allowedNFTContract.getApproved(_order.tokenId);

    require(_order.placedBy != msg.sender, "you cant accept your own offer");

    // if auction is on, you cant accept random offers
    require(isTokenAuctionEnabled[_order.tokenId] != true, "cant accept during auction");

    // if buyer booked an order for the token owner to approve
    if (_order.placedBy == _order.buyer) {
      require(
        tokenOwner == msg.sender || 
        tokenApprovedAddress == msg.sender ||
        permissionManagement.moderators(msg.sender) == true, 
        "only token owner can accept this offer"
      );

      _executeOrder(_orderId);
      allowedNFTContract.marketTransfer(tokenOwner, _order.buyer, _order.tokenId);
    } else {
      // if token owner/approved address, offered the buyer
      require(_order.buyer == msg.sender, "you werent offered");
      require(_order.placedBy == tokenOwner, "incompatible token owner");

      // require offer price
      require(msg.value >= _order.price, "insufficient amount sent");

      _executeOrder(_orderId);
      allowedNFTContract.marketTransfer(tokenOwner, _order.buyer, _order.tokenId);

      return _orderId;
    }

    return _orderId;
  }

  /// @notice Allows either party in an Order to cancel the Order
  /// @dev Cancels an Order
  /// @param _orderId ID of the Order to Cancel
  function cancelOffer(
    uint256 _orderId
  ) nonReentrant external returns(uint256) {
    Order memory _order = orders[_orderId];
    address tokenOwner = allowedNFTContract.ownerOf(_order.tokenId);
    address tokenApprovedAddress = allowedNFTContract.getApproved(_order.tokenId);

    require(_order.createdAt > 0, "invalid orderId");

    require(
      _order.placedBy == msg.sender || 
      tokenOwner == msg.sender || 
      tokenApprovedAddress == msg.sender ||
      permissionManagement.moderators(msg.sender) == true, 
      "you cant cancel this offer"
    );

    // if your bid was the highest on an auctioned token, and if it was above auction base price, then you cannot cancel
    if (
        auctions[getLatestAuctionIDByTokenID[_order.tokenId]].highestBidOrderId == _orderId &&
        _order.isDuringAuction == true &&
        _order.price >= auctions[getLatestAuctionIDByTokenID[_order.tokenId]].basePrice
    ) {
      revert("highest bid cant be cancelled during an Auction");
    }

    _cancelOrder(_orderId);

    return _orderId;
  }
}
