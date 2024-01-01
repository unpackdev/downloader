// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;

import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC721Holder.sol";

///@author Dualmint
///@title MarketV1
///@notice This is the declaration of the NFTMarket Contract for the Dualmint Markeplace that facilitates creation, buying, selling and auctions of tokenized versions of luxury items. 
///@dev This contract is upgradable to allow for expansion of the use cases and the features offered by the Dualmint Markeplace.
contract MarketV1 is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ERC1155HolderUpgradeable, ERC721Holder{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using SafeERC20Upgradeable for IERC20Upgradeable;


  // The MarketItem helps store each item on the Marketplace along with the relevant details of the asset and its current state. 
  struct MarketItem {
    bool isOnMarket;        // true if the item is currently on sale or auction in the Marketplace.
    bool isOnAuction;       // true if an item is currently on auction in the Marketplace.
    uint itemId;            // the id of the item in the Marketplace
    address nftContract;    // the address of the ERC1155 contract where the item was minted.
    uint256 tokenId;        // the tokenId of the asset in the ERC1155 contract where the item was minted
    address owner;          // the address of the current owner of the asset in the Marketplace.
    uint price;             // the listing price of the item in the Marketplace (NOTE: This is the base price if the item is on auction).       
    uint256 saleCount;      // the number of times the item has been traded on the Marketplace.
    bool pendingClaim;      // this variable is only true when someone wins an auction but has not claimed the item yet.
  }
  
  //The Auction struct helps store the relevant information about any ongoing auction of an item.
  struct Auction {
    uint  endAt;                        // the timestamp at which the auction ends
    bool started;                       // true if the auction has started
    bool ended;                         // true if the auction has ended
    address highestBidder;              // stores the address of the current highest bidder
    uint highestBid;                    // stores the current highest bid made by the highest bidder
    uint bidCount;                      // stores the number of bids for the current auction of an item
  }

  // The BidStruct helps store the details linked with each bid.
  struct BidStruct {
      address bidder;         // stores the address of the user who has bid on an item
      uint256 bid;            // stores the value of the bid
  }

  // The IncompleteRoyalties struct helps store the snapshot of the sale information in case of insufficient gas while executing the royalty loop.
  struct IncompleteRoyalties {
    uint itemId;                      // the item id of the asset
    uint royaltyOwnerIndexReached;    // the index of the last owner who was given royalty as a part of the royalty loop
    uint saleCount;                   // the number of times the asset was sold when the execution of the royalty loop was incomplete
    uint intermediaryBalance;         // the royalty to be assigned to each intermediary owner as per the royalty structure
    bool isComplete;                  // true when the incomplete execution has been completed 
  }

  // Struct for processing signatures which are splitted into v, r, s values (helps reduce number of arguments passed into function)
  struct Signature {
    uint8 v; 
    bytes32 r; 
    bytes32 s;
  }

  IERC20Upgradeable public tokenAddress; // The address of the ERC20 stablecoin contract on the ethereum blockchain network.
  CountersUpgradeable.Counter private _itemIds;// The number of items in the marketplace.
  CountersUpgradeable.Counter private _itemsOffMarket; // The number of items not currently on sale or auction.
  CountersUpgradeable.Counter public _incompleteRoyaltyIds; // This helps complete the unbounded royalty loop in case the user runs out of gas before the execution is completed. These IDs help store the snapshot of those sales to enable us to assign the promised royalties.

  ///  NOTE: The following royalty percentages are defined to be 10 * actual percentage to facilitate calculations with better precision and allowing definition of a wider range of values since floating point numbers are not supported.
  ///  This means that 10% is represented as 100 and the same has been accounted for when calculations are being made as the value is divided by 1000 instead of 100.
 
  uint256 public royaltiesPrecision;  // Precision value for calculating royalty.
  uint256 public royalties ;          // Percentage of sale amount distributed as royalties.
  uint256 public royaltyFirstOwner;   // Percentage of the the total royalty that is assigned to the first owner.
  uint256 public royaltyLastOwner;    // Percentage of the the total royalty that is assigned to the previous seller (NOTE: The last seller is the user who owned the asset before the current owner/seller, who has put it on sale). 
  //implicit royalty_intermediaries = 1 - percentage(royaltyFirstOwner) - percentage(royaltyLastOwner)// Percentage of the total royalty going to the the intermediaries*/
  address private deployer ;          // The address of the deployer of the marketplace (NOTE: Dualmint's wallet address, also referred to as admin). 
  uint256 public commissionPercent;   //  The percentage of commission received by Dualmint on each successful sale transaction.
  uint256 public gasThresholdForUserLoop; // Threshold of minimum gas required for the unbounded royalty loop when the user buys an asset to prevent DOS. 
  uint256 public gasThresholdForAdminLoop; // Threshold of minimum gas required for the unbounded royalty loop when the admin tries to complete the loop (to prevent DOS ).

  mapping (uint256 => IncompleteRoyalties) private incompleteRoyalties;   // stores the details of the incomplete royalty loops
  mapping (uint256 => Auction) private idToAuctionItem;                   // maps the item to its Auction Details
  mapping (uint256 => mapping(uint=>BidStruct)) public bids;              // maps the item to all its bids stored as BidStruct
  mapping(uint256 => MarketItem) private idToMarketItem;                  // maps each item in the MarketPlace to its details
  mapping (uint256 => mapping(uint256=>address)) public owners;           // stores all the owners of each item in the MarketPlace
  
  mapping (address => uint256) private pullableAmount;                    //deprecated (still exists because of original storage declaration before upgrade): maps the amount that can be withdrawn by the associated user (NOTE: PULL PAYMENT TO PREVENT SECURITY VULNERABILITIES)
  mapping (address => mapping(uint256=>bool)) public assets;              // mapping of already existing assets to prevent previously exsiting items to be introduced as new ones

  mapping (address => mapping(address => uint256)) public newPullableAmount;    // stores the mapping of user address -> currency address -> balance
  mapping (uint256 => address) idToCurrencyAddress;                             // stores the current currency address for a market item
  mapping (uint256 => address) incompleteRoyaltyIdtoCurrencyAddress;            // stores the currency address for incompleteRoyalty (in case the item is put on sale again before completion is executed)
  
  mapping(uint256 => bytes4) idToInterfaceId;                                   // stores the interface id for market item
  bytes4 private constant ERC1155InterfaceId = 0xd9b67a26;                      // ERC1155 interface id
  bytes4 private constant ERC721InterfaceId = 0x80ac58cd;                       // ERC721 interface id


  ///@notice An event that is triggered when a market item is created
  event MarketItemCreated ( 
    uint indexed itemId, 
    address nftContract, 
    uint256 tokenId, 
    address indexed seller, 
    uint256 price, 
    address currencyAddress,
    bool indexed isOnAuction
  );

  ///@notice An event that is triggered when a bid is received
  event Bid (
    uint indexed itemId, 
    address indexed sender, 
    uint amount,
    address currencyAddress
  );


  ///@notice An event that is triggered when an auction ends 
  event End(
    uint indexed itemId, 
    address indexed highestBidder, 
    uint highestBid,
    address currencyAddress
  );

  ///@notice An event that is triggered when a user balance is updated
  event Balances(
    uint indexed itemId, 
    address indexed puller, 
    uint indexed transactionType, //In event Balance transaction type// 0 is for withdrawing event // 1 is for direct sale // 2 is for royalty distribution
    uint256 amount,
    address currencyAddress
  ); 
  
  ///@notice An event that is triggered when a royalty distribution loop is not completed due to insufficient gas
  event IncompleteRoyalty(
    uint indexed royaltyId, 
    uint indexed itemId, 
    uint ownerReached, 
    uint lastOwnerForRoyaltyLoopIndex
  );

  ///@notice An event that is triggered when a previously incomplete royalty loop is run to completion by deployer
  event CompletedRoyalty(uint indexed royaltyId, uint indexed itemId);

  ///@notice An event that is triggered when a royalty percentage is changed
  event RoyaltiesReset(
    uint overallRoyalties, 
    uint firstOwnerRoyalty, 
    uint lastOwnerRoyalty
  );

  ///@notice An event that is triggered when an item is sold
  event CommissionsReset(uint commissionPercent);

  ///@notice An event that is triggered when a direct sale occurs
  event DirectSale(
    uint indexed itemId, 
    address indexed buyer, 
    address indexed seller, 
    uint price,
    address currencyAddress
  );

  ///@notice An event that is triggered when the auction winning user withdraws the item
  event WithdrawItem(uint indexed itemId, address indexed buyer);

  ///@notice An event that is triggered when an item is put on resale
  event ResellItem(
    uint indexed itemId, 
    address indexed seller, 
    uint price, 
    address currencyAddress,
    bool indexed isOnAuction
  );

  ///@notice An event that is triggered when user loop gas threshold is updated
  event UserGasThresholdChanged(uint newThreshold);

  ///@notice An event that is triggered when admin loop gas threshold is updated
  event AdminGasThresholdChanged(uint newThreshold);

  ///@notice An event that is triggered when the price is changed for an item that is on sale
  event PriceUpdated(uint256 itemId, uint256 newPrice, address newCurrencyAddress);

  ///@notice An event that is triggered when an item is taken off sale
  event CancelSale(uint256 itemId);

  ///@notice Initializing the upgradable contract in the required format
  // /// @custom:oz-upgrades-unsafe-allow constructor
  // constructor() {_disableInitializers();}
  // function initialize (address _tokenAddress) external initializer{
  //     royaltiesPrecision = 1000;
  //     royalties = 100;
  //     royaltyFirstOwner = 500;
  //     royaltyLastOwner = 200;
  //     commissionPercent = 25;
  //     gasThresholdForUserLoop = 250000;
  //     gasThresholdForAdminLoop = 200000;
  //     deployer = _msgSender();
  //     __Ownable_init();      
  //     __UUPSUpgradeable_init();
  //     __ReentrancyGuard_init();
  //     __ERC1155Holder_init();
  //     tokenAddress = IERC20Upgradeable(_tokenAddress);
  // }

  ///@notice  This function is used to set the threshold of minimum gas required for the unbounded royalty loop when the user buys an asset to prevent DOS. 
  ///@dev This function can only be called by the owner of the marketplace contract.
  ///@param newThreshold The threshold value to be set by the owner.
  function setGasThresholdForUserLoop (
    uint256 newThreshold
  ) 
    external 
    onlyOwner 
  {
    require(newThreshold > 0,"value too low");
    gasThresholdForUserLoop = newThreshold;
    emit UserGasThresholdChanged(newThreshold);
  }

  ///@notice  This function is used to set the threshold of minimum gas required for the unbounded royalty loop when the admin tries to complete the loop (to prevent DOS).
  ///@dev This function can only be called by the owner of the marketplace contract.
  ///@param newThreshold The threshold value to be set by the owner.
  function setGasThresholdForAdminLoop (
    uint256 newThreshold
  ) 
    external 
    onlyOwner 
  {
    require(newThreshold > 0,"value too low");
    gasThresholdForAdminLoop = newThreshold;
    emit AdminGasThresholdChanged(newThreshold);
  }

  
  ///@notice This function can be used to change the percentages of royalties
  ///@dev The function allows multiple or only one value to be changed. If a previous value of the variable is to be maintained, instead of passing the same value as an argument again, a value higher than 1000 can be passed as the case handling accounts for that
  ///@param _royalties The overall royalty percentage associated with the sale value.
  ///@param _royaltyFirstOwner The royalty of the first owner.
  ///@param _royaltyLastOwner  The royalty of the previous seller. 
  function setRoyalties(
    uint _royalties, 
    uint _royaltyFirstOwner, 
    uint _royaltyLastOwner
  ) 
    external 
    onlyOwner
  {
    require(_royalties+commissionPercent<royaltiesPrecision, "overall royalties too high");
    require(_royaltyFirstOwner+_royaltyLastOwner<royaltiesPrecision,"owner percentages too high");
    royalties = _royalties;
    royaltyFirstOwner = _royaltyFirstOwner;
    royaltyLastOwner = _royaltyLastOwner;
    emit RoyaltiesReset(royalties,royaltyFirstOwner,royaltyLastOwner);
  }

  
  ///@notice This function can be used to change the commision percentage of the Marketplace
  ///@param _commissionPercent  The new commision percentage 
  function setCommissionPercent(uint256 _commissionPercent) external onlyOwner {
    require(royalties+_commissionPercent<royaltiesPrecision, "commissionPercent too high");
    commissionPercent = _commissionPercent;
    emit CommissionsReset(commissionPercent);
  }
  
  ///@notice This function is used to add the new variables associated with the market items which were not a part of the previous logic
  function upgradeRestructure() external onlyOwner {
    uint itemCount = _itemIds.current();
    for (uint i = 1; i <= itemCount; i++) {
      idToCurrencyAddress[i] = address(tokenAddress);
      idToInterfaceId[i] = ERC1155InterfaceId;
    }
  }
  
  ///@notice This function can be used to update the price of an item that has been put on sale
  ///@dev if bids are already placed for an auction type sale, the price cannot be updated
  ///@param itemId The id of the item whose price needs to be updated
  ///@param newPrice The updated price value
  ///@param currencyAddress The updated currency address
  function updatePrice(uint256 itemId, uint256 newPrice, address currencyAddress) external {
    require(idToMarketItem[itemId].owner == _msgSender(), "You are not the owner");
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    if (idToMarketItem[itemId].isOnAuction){
      require(idToAuctionItem[itemId].bidCount == 0, "Bids already placed");
      idToAuctionItem[itemId].highestBid = newPrice;
    }
    idToMarketItem[itemId].price = newPrice;
    idToCurrencyAddress[itemId] = currencyAddress;
    emit PriceUpdated(itemId, newPrice, currencyAddress);
  }

  ///@notice This function can be used to take an item off the marketplace
  ///@dev if bids are already placed for an auction type sale, this cannot be called
  ///@param itemId The id of the item whose sale needs to be cancelled
  function cancelSale(uint256 itemId) external {
    require(idToMarketItem[itemId].owner == _msgSender(), "You are not the owner");
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    if (idToMarketItem[itemId].isOnAuction){
      require(idToAuctionItem[itemId].bidCount == 0, "Bids already placed");
      idToAuctionItem[itemId] = Auction(// solhint-disable-next-line not-rely-on-time
        block.timestamp,
        false,
        true,
        address(0),
        idToMarketItem[itemId].price,
        0
      );
      idToMarketItem[itemId].isOnAuction = false;
    } 
    safeTransferItemFrom(address(this), idToMarketItem[itemId].owner, itemId, "Cancel Sale");
    idToMarketItem[itemId].isOnMarket = false;
    _itemsOffMarket.increment();
    emit CancelSale(itemId);
  }

  ///@notice This function is called to put an asset on sale (or auction) on the Dualmint Marketplace
  ///@dev Approval from the nftContract is required before executing this function. Only ERC721 and ERC1155 are supported (along with their extensions)
  ///@param nftContract  The address of the ERC1155 contract where the item was minted
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price)
  ///@param isAuctionItem  True if item has been put on auction
  ///@param numDays The number of seconds for which the item is on auction
  ///@param _hash The hash created for the creation of market item
  ///@param signature The signature of approval from Dualmint for creating this market item
  ///@param interfaceId The interface of the current token (i.e. ERC721 or ERC1155)
  function createMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    address currencyAddress,
    bool isAuctionItem, 
    uint256 numDays,
    bytes32 _hash, 
    Signature calldata signature,
    bytes4 interfaceId
  ) 
    external 
    nonReentrant 
  {
    creationOfMarketItem(
      nftContract, 
      tokenId, 
      price, 
      currencyAddress,
      isAuctionItem, 
      numDays, 
      _msgSender(),
      _hash,
      signature,
      interfaceId
    );
  }

  ///@notice This function is called by Dualmint to put an asset on sale (or auction) on behalf of a customer
  ///@dev Approval from the nftContract is required before executing this function
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  ///@param assetOwner The desired owner of the item.
  ///@param _hash The hash created for the creation of market item
  ///@param signature The signature of approval from Dualmint for creating this market item
  ///@param interfaceId The interface of the current token (i.e. ERC721 or ERC1155)
  function assistedCreateMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    address currencyAddress,
    bool isAuctionItem, 
    uint256 numDays, 
    address assetOwner,
    bytes32 _hash, 
    //bytes memory signature,
    Signature calldata signature,
    bytes4 interfaceId
  ) 
    external 
    onlyOwner
  {
    creationOfMarketItem(
      nftContract, 
      tokenId, 
      price, 
      currencyAddress,
      isAuctionItem, 
      numDays,
      assetOwner,
      _hash,
      signature,
      interfaceId
    );
  }

  ///@notice The function to place a bid on an item that is currently on auction
  ///@dev Approval for the Marketplace is required from the bidder on the ERC20 contract stored at tokenAddress to transfer amount
  ///@param itemId The id of the item on which the bid is to be placed
  ///@param amount The bid amount.
  function createBid(uint256 itemId, uint256 amount) external payable nonReentrant{
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    require(idToMarketItem[itemId].isOnAuction, "Currently not on auction");
    require(amount>idToAuctionItem[itemId].highestBid, "Lower bid than acceptable");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < idToAuctionItem[itemId].endAt, "ended"); // this condition ensures that the item is currently on auction and the bid is being made is the specified period
    address currencyAddress = idToCurrencyAddress[itemId];
    currencySafeTransferFrom(_msgSender(), address(this), amount, currencyAddress);    
    if (idToAuctionItem[itemId].highestBidder != address(0)) {  // if this is not the first bid, then the previous bid is saved and the previous bidder can withdraw their funds
      bids[itemId][idToAuctionItem[itemId].bidCount] = BidStruct(
        idToAuctionItem[itemId].highestBidder,
        idToAuctionItem[itemId].highestBid
      );//mapping (uint256 => mapping(uint=>BidStruct)) public bids;  
      newPullableAmount[idToAuctionItem[itemId].highestBidder][currencyAddress] += idToAuctionItem[itemId].highestBid;
    }
    idToAuctionItem[itemId].bidCount += 1;
    idToAuctionItem[itemId].highestBidder = _msgSender();
    idToAuctionItem[itemId].highestBid = amount;
    emit Bid(itemId,_msgSender(),amount, currencyAddress);
  }

  
  ///@notice This is called once the auction period is over
  ///@dev For the auction to be completed and the funds and asset to be distributed, an external call is required
  ///@param itemId The itemId whose auction is over
  function endAuction(uint256 itemId) external nonReentrant {
        require(idToMarketItem[itemId].isOnAuction, "Currently not on auction");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= idToAuctionItem[itemId].endAt, "not ended");
        require(!idToAuctionItem[itemId].ended, "ended");
        address currencyAddress = idToCurrencyAddress[itemId];
        if (idToAuctionItem[itemId].highestBidder == address(0)) {  //in case there are no bids for the item the ownership is transferred back to the user who listed
            safeTransferItemFrom(address(this), idToMarketItem[itemId].owner, itemId, "No Bids");
            idToMarketItem[itemId].isOnMarket = false;
            _itemsOffMarket.increment();
        } else {  // if bids were made successfully, the normal distribution of royalty and transfer of assets and assignment of balances shall take place
            distributionOfFundsAndAssets(
              idToAuctionItem[itemId].highestBid,
              idToAuctionItem[itemId].highestBidder, 
              itemId,
              currencyAddress
            );
            idToMarketItem[itemId].pendingClaim = true;
        }
        idToMarketItem[itemId].price = idToAuctionItem[itemId].highestBid;
        //resetting state variables to default values
        idToAuctionItem[itemId] = Auction(// solhint-disable-next-line not-rely-on-time
          block.timestamp,
          false,
          true,
          address(0),
          idToMarketItem[itemId].price,
          0
        );
        idToMarketItem[itemId].isOnAuction = false;
        emit End(itemId, idToAuctionItem[itemId].highestBidder, idToAuctionItem[itemId].highestBid, currencyAddress);
  }

  ///@notice This function executes the direct sale of an asset 
  ///@dev This can only be called for an item that is not on auction
  ///@param itemId The itemId of the asset to be on sold
  function directMarketSale(uint256 itemId) external payable nonReentrant {
    require(!idToMarketItem[itemId].isOnAuction,"Sale type is auction");  
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    address currencyAddress = idToCurrencyAddress[itemId];
    uint currentPrice = idToMarketItem[itemId].price;
    currencySafeTransferFrom(_msgSender(), address(this), currentPrice, currencyAddress);
    distributionOfFundsAndAssets(idToMarketItem[itemId].price, _msgSender(), itemId, currencyAddress);   // distribution of royalties and transfer of assets and assignment of balances shall take place
    safeTransferItemFrom(address(this), _msgSender(), itemId, "DirectSale");
    emit DirectSale(
      itemId, 
      _msgSender(), 
      owners[itemId][idToMarketItem[itemId].saleCount-1], 
      currentPrice,
      currencyAddress
    );
  }
  
  ///@notice This function is called by the user to withdraw the asset purchased on the Marketplace.
  ///@dev This function is called to implement the pull payment mechanism for ERC1155 assets to avoid DOS.
  ///@param itemId The itemId of the asset purchased by the user on the Marketplace.
  function withdrawItem(uint256 itemId) external nonReentrant{
    require(idToMarketItem[itemId].pendingClaim==true,"cannot withdraw");
    require(idToMarketItem[itemId].owner==_msgSender(), "not your asset");
    idToMarketItem[itemId].pendingClaim=false;
    safeTransferItemFrom(address(this), _msgSender(), itemId, "AuctionWinner");
    emit WithdrawItem(itemId, _msgSender());
  }

  ///@notice This function executes the listing for sale of an asset previously purchased on the marketplace.
  ///@dev The approval from the nftContract is required for transferring the ownership of the asset to the marketplace contract.
  ///@param itemId The itemId of the asset to be resold
  ///@param price The price at which the item is listed for resale on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  function resellItem(uint256 itemId, uint256 price, address currencyAddress, bool isAuctionItem, uint256 numDays) external {
    require(!idToMarketItem[itemId].isOnMarket,"The Item is already on sale");
    safeTransferItemFrom(_msgSender(), address(this), itemId, "ResellItem");
    if (_msgSender()!=idToMarketItem[itemId].owner){
      idToMarketItem[itemId].owner = _msgSender();
      owners[itemId][idToMarketItem[itemId].saleCount] = _msgSender();
    }// TODO: NOTE: questionable
    idToMarketItem[itemId].isOnMarket = true;
    idToMarketItem[itemId].isOnAuction = isAuctionItem;
    idToMarketItem[itemId].price = price;
    idToCurrencyAddress[itemId] = currencyAddress;
    _itemsOffMarket.decrement();
    if(isAuctionItem){
      // solhint-disable-next-line not-rely-on-time
      idToAuctionItem[itemId] = Auction(block.timestamp+numDays, true, false, address(0), price, 0);
    }
    emit ResellItem(itemId, _msgSender(), price, currencyAddress, isAuctionItem);
  }

  ///@notice This function is used to complete any incomplete royalty loops that had insufficient gas for execution
  ///@dev This function can only be called by the deployer and in case the gas is still not sufficient, this can be recalled and acounts for the stated condition by saving the state of its last execution.
  ///@param incompleteRoyaltyId The ID of the incomplete royalty event
  function completeRoyaltyLoop(uint incompleteRoyaltyId) external onlyOwner{
    require(!incompleteRoyalties[incompleteRoyaltyId].isComplete,"already completed");
    address currencyAddress = incompleteRoyaltyIdtoCurrencyAddress[incompleteRoyaltyId];
    uint i = incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached+1;
    for (
      i; 
      i < incompleteRoyalties[incompleteRoyaltyId].saleCount - 2  && gasleft()>gasThresholdForAdminLoop;
      i++
    )
    { //royalty for intermediary owners who have not been assigned the royalty yet
      newPullableAmount[owners[incompleteRoyalties[incompleteRoyaltyId].itemId][i]][currencyAddress]+=
        incompleteRoyalties[incompleteRoyaltyId].intermediaryBalance;
      emit Balances(
        incompleteRoyalties[incompleteRoyaltyId].itemId, 
        owners[incompleteRoyalties[incompleteRoyaltyId].itemId][i], 
        2, 
        incompleteRoyalties[incompleteRoyaltyId].intermediaryBalance,
        currencyAddress
      );
    }
    if(i!=incompleteRoyalties[incompleteRoyaltyId].saleCount-2){  // the case where there is not enough gas to complete the royalty loop, state of last execution is saved, event is emitted and can be called again
      emit IncompleteRoyalty(
        incompleteRoyaltyId, 
        incompleteRoyalties[incompleteRoyaltyId].itemId, 
        i-1, 
        incompleteRoyalties[incompleteRoyaltyId].saleCount
      );
      incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached = i;
    } else {  // in case the loop has reached the end
      incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached = i;// optional
      incompleteRoyalties[incompleteRoyaltyId].isComplete = true;
      emit CompletedRoyalty(incompleteRoyaltyId, incompleteRoyalties[incompleteRoyaltyId].itemId);
    }
  }

  ///@notice This function enables the user to withdraw the balances assigned to them
  ///@dev This function can be called by anyone on behalf of the user in case they do not have enough gas to execute it. Further, reentrancy has been secured against by changing the state variable before the execution of transfer.
  ///@param payee The address of the user whose balance is to be withdrawn
  function withdrawFundsForCurrency(address payee, address currencyAddress) external nonReentrant{
    require(newPullableAmount[payee][currencyAddress]>0,"No balance to withdraw");
    uint256 currentBalance = newPullableAmount[payee][currencyAddress];
    newPullableAmount[payee][currencyAddress]=0;
    // bool transferSuccessful = tokenAddress.transfer(payee,currentBalance);
    // require(transferSuccessful,"transfer of tokens unsuccessful");
    currencySafeTransfer(payee, currentBalance, currencyAddress);
    emit Balances(0, payee, 0, currentBalance, currencyAddress);
  }  
  
  ///@notice This function is used to handle safeTransferFrom as well as with native currency
  ///@dev If currencyAddress is address(0), native currency is processed
  ///@param from The address from which the currency needs to be transferred
  ///@param to The address to which the currency needs to be transferred
  ///@param amount The amount which needs to be transferred
  ///@param currencyAddress The address of the ERC20 token that needs to be transferred (See @dev)
  function currencySafeTransferFrom(address from, address to, uint amount, address currencyAddress) internal {
    if(currencyAddress==address(0)){
        require(msg.value==amount,"Send exact native currency");
    } else {
        IERC20Upgradeable currentTokenAddress = IERC20Upgradeable(currencyAddress);
        require(currentTokenAddress.allowance(from, to)>=amount,"insufficient allowance");
        IERC20Upgradeable(currentTokenAddress).safeTransferFrom(from, to, amount);
    }
  }
  
  ///@notice This function is used to handle safeTransfer of ERC20 tokens as well as with native currency
  ///@dev If currencyAddress is address(0), native currency is processed
  ///@param to The address to which the currency needs to be transferred
  ///@param amount The amount which needs to be transferred
  ///@param currencyAddress The address of the ERC20 token that needs to be transferred (See @dev)
  function currencySafeTransfer(address to, uint amount, address currencyAddress) internal {
    if(currencyAddress==address(0)) {
        (bool sent, bytes memory data) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    } else {
        IERC20Upgradeable currentTokenAddress = IERC20Upgradeable(currencyAddress);
        IERC20Upgradeable(currentTokenAddress).safeTransfer(to, amount);
    }
  }

  ///@notice This function is used to get the items currently on sale or auction in the marketplace.
  ///@return MarketItems currently on sale or auction in the marketplace (i.e. items with isOnMarket value stored as true).
  function fetchMarketItems() external view returns (MarketItem[] memory, address[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsOffMarket.current();
    uint currentIndex = 0;
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    address[] memory currencyAddresses = new address[](unsoldItemCount);
    for (uint i = 1; i <= itemCount; i++) {
      if(idToMarketItem[i].isOnMarket){
        uint currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currencyAddresses[currentIndex] = idToCurrencyAddress[currentId];
        currentIndex += 1;
      } 
    }
    return (items, currencyAddresses);
  }

  ///@notice This function is used to get all the items in the marketplace irrespective of whether they are on sale or not.
  ///@return MarketItems in the Marketplace (irrespective of whether they are on sale or not) along with address array with their corresponding currencyAddress
  function fetchAllItems() external view returns (MarketItem[] memory, address[] memory) {
    MarketItem[] memory items = new MarketItem[](_itemIds.current());
    address[] memory currencyAddresses = new address[](_itemIds.current());
    for (uint i = 0; i < _itemIds.current(); ++i){
        MarketItem storage currentItem = idToMarketItem[i+1];
        items[i] = currentItem;
        currencyAddresses[i] = idToCurrencyAddress[i+1];
    }
    return (items, currencyAddresses);
  }
  
  ///@notice This function is used to get all the items currently owned by the msg.sender
  ///@dev This includes the items put on sale by the msg.sender too which are not currently sold
  ///@return MarketItems currently owned by the msg.sender along with their corresponding currencyAddresses in a separate array
  function fetchMyNFTs() external view returns (MarketItem[] memory, address[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == _msgSender()) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    address[] memory currencyAddresses = new address[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == _msgSender()) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currencyAddresses[currentIndex] = idToCurrencyAddress[currentId];
        currentIndex += 1;
      }
    }
    return (items,currencyAddresses);
  }


  ///@notice This function is used to get all the items created by the msg.sender
  ///@return MarketItems created by the msg.sender along with their corresponding currencyAddresses in a separate array
  function fetchItemsCreated() external view returns (MarketItem[] memory, address[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (owners[i+1][0] == _msgSender()) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    address[] memory currencyAddresses = new address[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (owners[i+1][0] == _msgSender()) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currencyAddresses[currentIndex] = idToCurrencyAddress[currentId];
        currentIndex += 1;
      }
    }
    return (items, currencyAddresses) ;
  }
  
  ///@notice This function is used to get auction details of an item
  ///@param itemId The item id whose auction details are to be retrieved
  ///@return AuctionDetails of the itemId
  function fetchAuctionItemsDetails(uint256 itemId) external view returns (Auction memory) {
    return idToAuctionItem[itemId];
  }

  ///@notice This function is used to check the withdrawable balance of the user for a particular currencyAddress
  ///@param payee The address of the user
  ///@param currencyAddress The address of the currency whose balance needs to be fetched
  ///@dev The balance is returned with the precision of the ERC20 currency
  ///@return Balance of the user
  function checkBalanceForCurrency(address payee, address currencyAddress) external view returns(uint256){
    return newPullableAmount[payee][currencyAddress];
  }

  ///@notice This function returns the signer for the hash
  ///@dev This is needed to verify Dualmint's approval for listing assets
  function recoverSigner(bytes32 _hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    return ECDSAUpgradeable.recover(messageDigest, v, r, s);
  }
  
  ///@notice This function is called by both createMarketItem and assistedCreateMarketItem to put an asset on sale(or auction) on the Dualmint Marketplace, avoiding the duplication of code.
  ///@dev This function is an internal function.
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  ///@param assetOwner The desired owner of the item.
  ///@param _hash The hash created for the creation of market item
  ///@param signature The signature of approval from Dualmint for creating this market item
  ///@param interfaceId The interface of the current token (i.e. ERC721 or ERC1155)
  function creationOfMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    address currencyAddress,
    bool isAuctionItem, 
    uint256 numDays, 
    address assetOwner,
    bytes32 _hash, 
    Signature calldata signature,
    bytes4 interfaceId
  ) 
    internal
  {
    require(price > 0, "Price must be at least 1");
    require(assets[nftContract][tokenId]==false,"asset already exists");
    require(keccak256(abi.encodePacked(DOMAIN_SEPARATOR(), nftContract, tokenId))==_hash,"Incorrect details passed"); //TODO: ENCODE PACKED MAY BE UNSAFE?
    require(recoverSigner(_hash, signature.v, signature.r, signature.s)==owner(), "Signature invalid");
    assets[nftContract][tokenId] = true;
    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    idToMarketItem[itemId] = MarketItem(
      true, 
      isAuctionItem, 
      itemId, 
      nftContract, 
      tokenId, 
      assetOwner, 
      price, 
      0,
      false
    ); 
    idToInterfaceId[itemId] = interfaceId;
    owners[itemId][0] = assetOwner;
    safeTransferItemFrom(_msgSender(),address(this), itemId, "MarketItemCreated");
    if(isAuctionItem){
      // solhint-disable-next-line not-rely-on-time
      idToAuctionItem[itemId] = Auction(block.timestamp+numDays, true, false, address(0), price, 0);//NOTE BREAKING PRICE - 1 change?
    }
    idToCurrencyAddress[itemId] = currencyAddress;
    emit MarketItemCreated(itemId, nftContract, tokenId, assetOwner, price, currencyAddress, isAuctionItem);
  }

  ///@notice This function executes the royalty loop, transfer of assets, and assignment of balances
  ///@dev The unbounded loop condition is handled by storing the current state of the execution in case the gas is insufficient and can be completed by calling completeRoyaltyLoop
  ///@param price The final price at which the asset is purchased
  ///@param buyer The user about to receive the asset
  ///@param itemId The asset associated with the sale
  ///@param currencyAddress The currencyAddress associated with the current sale
  function distributionOfFundsAndAssets(uint price, address buyer, uint itemId, address currencyAddress) internal {
    idToMarketItem[itemId].saleCount+=1;
    uint saleCount = idToMarketItem[itemId].saleCount;
    uint256 marketplaceCommission = ((price * commissionPercent)/royaltiesPrecision);
    newPullableAmount[deployer][currencyAddress]+= marketplaceCommission; // assigning commission to the marketplace
    emit Balances(itemId, deployer, 1, marketplaceCommission, currencyAddress);
    //allocation of sale price and royalties
    if(saleCount==1){
      // a -> b
      //if it is the first sale, the seller gets all the money
      uint256 sellerBalance = (((royaltiesPrecision-commissionPercent)*price)/royaltiesPrecision);
      newPullableAmount[idToMarketItem[itemId].owner][currencyAddress]+=sellerBalance;
      emit Balances(itemId, idToMarketItem[itemId].owner, 1, sellerBalance, currencyAddress);
    } else if (saleCount==2){
      // a -> b -> c
      //if it is the second sale
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties)/royaltiesPrecision);
      newPullableAmount[owners[itemId][0]][currencyAddress]+= firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance, currencyAddress);
      //seller gets the sale price ( - royalty - commission)
      uint256 sellerBalance = ((price*(royaltiesPrecision-royalties-commissionPercent))
        /royaltiesPrecision);
      newPullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]][currencyAddress]+=sellerBalance;
      emit Balances(itemId, owners[itemId][idToMarketItem[itemId].saleCount-1], 1 ,sellerBalance, currencyAddress);
    } else if (saleCount==3){
      // a-> b -> c -> d
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties*royaltyFirstOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      newPullableAmount[owners[itemId][0]][currencyAddress]+=firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance, currencyAddress);
      // royalty to last seller
      uint256 lastOwnerBalance = ((price*royalties*(royaltiesPrecision-royaltyFirstOwner))
        /(royaltiesPrecision*royaltiesPrecision));
      newPullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-2]][currencyAddress]+=lastOwnerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-2] , 2, lastOwnerBalance, currencyAddress);
      //seller gets the sale price ( - royalty - commission)
      uint256 sellerBalance = ((price*(royaltiesPrecision-royalties-commissionPercent))
        /royaltiesPrecision);
      newPullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]][currencyAddress]+=sellerBalance;
      emit Balances(itemId, owners[itemId][idToMarketItem[itemId].saleCount-1], 1 ,sellerBalance, currencyAddress);
    } else { // this condition is hit when saleCount>3
      // a->b->c->.....->w->x->y->z
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties*royaltyFirstOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      newPullableAmount[owners[itemId][0]][currencyAddress]+= firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance, currencyAddress);
      // royalty to last seller
      uint256 lastOwnerBalance = ((price*royalties*royaltyLastOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      newPullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-2]][currencyAddress]+=lastOwnerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-2] , 2, lastOwnerBalance, currencyAddress);
      // selling price - commission given to seller
      uint256 sellerBalance = ((price*(royaltiesPrecision - royalties - commissionPercent))
        /royaltiesPrecision);
      newPullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]][currencyAddress]+=sellerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-1], 1,  sellerBalance, currencyAddress);
      // intermediaries get royalty
      uint256 intermediaryBalance = ((price*royalties
        *(royaltiesPrecision-royaltyFirstOwner-royaltyLastOwner))
        /(royaltiesPrecision*royaltiesPrecision))
        /(idToMarketItem[itemId].saleCount-3);
      uint i=1;
      for (i;i< idToMarketItem[itemId].saleCount-2 && gasleft()>gasThresholdForUserLoop; i++){ //royalty distributed among intermediary owners
        newPullableAmount[owners[itemId][i]][currencyAddress] += intermediaryBalance;
        emit Balances(itemId, owners[itemId][i], 2, intermediaryBalance, currencyAddress);
      }
      if(i!=idToMarketItem[itemId].saleCount-2){ // in case the gas is insufficient to complete the royalty loop, then the state is stored
        _incompleteRoyaltyIds.increment();
        uint royaltyId = _incompleteRoyaltyIds.current();
        incompleteRoyalties[royaltyId] = IncompleteRoyalties(
          itemId, 
          i-1, 
          idToMarketItem[itemId].saleCount, 
          intermediaryBalance, 
          false
        );
        incompleteRoyaltyIdtoCurrencyAddress[royaltyId] = currencyAddress;
        emit IncompleteRoyalty(royaltyId, itemId, i, idToMarketItem[itemId].saleCount);
      }
    }
    owners[itemId][idToMarketItem[itemId].saleCount]= buyer; // the new owner is _msgSender()
    idToMarketItem[itemId].isOnMarket = false;  // resetting
    idToMarketItem[itemId].owner = buyer;
    _itemsOffMarket.increment();
  }
  ///@notice This function is used to handle safeTransferFrom for ERC721 and ERC1155 tokens
  ///@dev The marketplace address needs to be approved for this
  ///@param from The address from which the token needs to be transferred
  ///@param to The address to which the token needs to be transferred
  ///@param itemId The id of the item which needs to be transferred
  ///@param data The data associated with this transfer
  function safeTransferItemFrom(address from, address to, uint itemId, bytes memory data) internal {
    if(idToInterfaceId[itemId] == ERC1155InterfaceId){
      IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
        from,
        to,
        idToMarketItem[itemId].tokenId,
        1,
        data
      );
    } else if ( idToInterfaceId[itemId] == ERC721InterfaceId) {
      IERC721Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
        from,
        to,
        idToMarketItem[itemId].tokenId,
        data
      );
    } else {
      require(false,"Unknown InterfaceId");
    }
  }

  ///@notice The Domain separator associated with this particular chain
  ///@dev This helps misuse of signatures across domains
  function DOMAIN_SEPARATOR()
    public
    view
    virtual
    returns (
        bytes32 _hash
    )
  {
    return keccak256(
        abi.encode(
          "Dualmint Marketplace", //name
          "1.0",                  //version
          block.chainid,          //chainid
          address(this),          
          bytes32(0x9653e33700788b1a9c321411f1573f08b17cdf6bf8a24e3f2f9245def8d47497)              //salt
        )
    );
  }

  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}
}
