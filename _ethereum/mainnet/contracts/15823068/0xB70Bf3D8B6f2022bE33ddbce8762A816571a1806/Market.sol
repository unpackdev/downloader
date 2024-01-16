// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;

import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";


///@author Dualmint
///@title NFTMarket
///@notice This is the declaration of the NFTMarket Contract for the Dualmint Markeplace that facilitates creation, buying, selling and auctions of tokenized versions of luxury items. 
///@dev This contract is upgradable to allow for expansion of the use cases and the features offered by the Dualmint Markeplace.
///NOTE: The transfers of assets and currencies do not need to be verified with the returned boolean value as per the new updates in ERC20 and ERC1155 transfer standards, since when the transfer fails the execution is reverted.
contract NFTMarket is Initializable,UUPSUpgradeable,ReentrancyGuardUpgradeable,OwnableUpgradeable,ERC1155HolderUpgradeable{
  using CountersUpgradeable for CountersUpgradeable.Counter;

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

  IERC20Upgradeable public tokenAddress; // The address of the ERC20 stablecoin contract on the ethereum blockchain network.
  CountersUpgradeable.Counter private _itemIds;// The number of items in the marketplace.
  CountersUpgradeable.Counter private _itemsOffMarket; // The number of items not currently on sale or auction.
  CountersUpgradeable.Counter public _incompleteRoyaltyIds; // This helps complete the unbounded royalty loop in case the user runs out of gas before the execution is completed. These IDs help store the snapshot of those sales to enable us to assign the promised royalties.

  ///  NOTE: The following royalty percentages are defined to be 10 * actual percentage to facilitate calculations with better precision and allowing definition of a wider range of values since floating point numbers are not supported.
  ///  This means that 10% is represented as 100 and the same has been accounted for when calculations are being made as the value is divided by 1000 instead of 100.
 
  uint256 public royaltiesPrecision;
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
  mapping (address => uint256) private pullableAmount;                    // maps the amount that can be withdrawn by the associated user (NOTE: PULL PAYMENT TO PREVENT SECURITY VULNERABILITIES)
  mapping (address => mapping(uint256=>bool)) public assets;              // mapping of already existing assets to prevent previously exsiting items to be introduced as new ones

  ///@notice An event that is triggered when a market item is created
  event MarketItemCreated ( 
    uint indexed itemId, 
    address nftContract, 
    uint256 tokenId, 
    address indexed seller, 
    uint256 price, 
    bool indexed isOnAuction
  );

  ///@notice An event that is triggered when a bid is received
  event Bid (
    uint indexed itemId, 
    address indexed sender, 
    uint amount
  );

  ///@notice An event that is triggered when an auction ends 
  event End(
    uint indexed itemId, 
    address indexed highestBidder, 
    uint highestBid
  );

  ///@notice An event that is triggered when a user balance is updated
  event Balances(
    uint indexed itemId, 
    address indexed puller, 
    uint indexed transactionType, //In event Balance transaction type// 0 is for withdrawing event // 1 is for direct sale // 2 is for royalty distribution
    uint256 amount
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
    uint price
  );

  ///@notice An event that is triggered when the auction winning user withdraws the item
  event WithdrawItem(uint indexed itemId, address indexed buyer);

  ///@notice An event that is triggered when an item is put on resale
  event ResellItem(
    uint indexed itemId, 
    address indexed seller, 
    uint price, 
    bool indexed isOnAuction
  );

  ///@notice An event that is triggered when user loop gas threshold is updated
  event UserGasThresholdChanged(uint newThreshold);

  ///@notice An event that is triggered when admin loop gas threshold is updated
  event AdminGasThresholdChanged(uint newThreshold);

  ///@notice Initializing the upgradable contract in the required format
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {_disableInitializers();}
  

  function initialize (address _tokenAddress) external initializer{
      royaltiesPrecision = 1000;
      royalties = 100;
      royaltyFirstOwner = 500;
      royaltyLastOwner = 200;
      commissionPercent = 25;
      gasThresholdForUserLoop = 250000;
      gasThresholdForAdminLoop = 200000;
      deployer = _msgSender();
      __Ownable_init();      
      __UUPSUpgradeable_init();
      __ReentrancyGuard_init();
      __ERC1155Holder_init();
      tokenAddress = IERC20Upgradeable(_tokenAddress);
  }


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

  
  ///@notice This function is called to put an asset on sale (or auction) on the Dualmint Marketplace
  ///@dev Approval from the nftContract is required before executing this function
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  function createMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    bool isAuctionItem, 
    uint256 numDays
  ) 
    external 
    nonReentrant 
  {
    creationOfMarketItem(
      nftContract, 
      tokenId, 
      price, 
      isAuctionItem, 
      numDays, 
      _msgSender()
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
  function assistedCreateMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    bool isAuctionItem, 
    uint256 numDays, 
    address assetOwner
  ) 
    external 
    onlyOwner
  {
    creationOfMarketItem(
      nftContract, 
      tokenId, 
      price, 
      isAuctionItem, 
      numDays,
      assetOwner
    );
  }

  
  ///@notice The function to place a bid on an item that is currently on auction
  ///@dev Approval for the Marketplace is required from the bidder on the ERC20 contract stored at tokenAddress to transfer amount
  ///@param itemId The id of the item on which the bid is to be placed
  ///@param amount The bid amount.
  function createBid(uint256 itemId, uint256 amount) external nonReentrant{
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    require(idToMarketItem[itemId].isOnAuction, "Currently not on auction");
    require(amount>idToAuctionItem[itemId].highestBid, "Lower bid than acceptable");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < idToAuctionItem[itemId].endAt, "ended"); // this condition ensures that the item is currently on auction and the bid is being made is the specified period
    require(tokenAddress.allowance(_msgSender(), address(this))>=amount,"insufficient allowance");
    bool transferSuccessful = tokenAddress.transferFrom(_msgSender(),address(this),amount); // transfer of funds to marketplace contract
    require(transferSuccessful,"transfer of tokens unsuccessful"); //)
    if (idToAuctionItem[itemId].highestBidder != address(0)) {  // if this is not the first bid, then the previous bid is saved and the previous bidder can withdraw their funds
      bids[itemId][idToAuctionItem[itemId].bidCount] = BidStruct(
        idToAuctionItem[itemId].highestBidder,
        idToAuctionItem[itemId].highestBid
      );//mapping (uint256 => mapping(uint=>BidStruct)) public bids;  
      pullableAmount[idToAuctionItem[itemId].highestBidder] += idToAuctionItem[itemId].highestBid;
    }
    idToAuctionItem[itemId].bidCount += 1;
    idToAuctionItem[itemId].highestBidder = _msgSender();
    idToAuctionItem[itemId].highestBid = amount;
    emit Bid(itemId,_msgSender(),amount);
  }

  
  ///@notice This is called once the auction period is over
  ///@dev For the auction to be completed and the funds and asset to be distributed, an external call is required
  ///@param itemId The itemId whose auction is over
  function endAuction(uint256 itemId) external {
        require(idToMarketItem[itemId].isOnAuction, "Currently not on auction");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= idToAuctionItem[itemId].endAt, "not ended");
        require(!idToAuctionItem[itemId].ended, "ended");
        if (idToAuctionItem[itemId].highestBidder == address(0)) {  //in case there are no bids for the item the ownership is transferred back to the user who listed
            IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
              address(this), 
              idToMarketItem[itemId].owner, 
              idToMarketItem[itemId].tokenId,
              1,
              "No bids"
            );
            idToMarketItem[itemId].isOnMarket = false;
            _itemsOffMarket.increment();
        } else {  // if bids were made successfully, the normal distribution of royalty and transfer of assets and assignment of balances shall take place
            distributionOfFundsAndAssets(
              idToAuctionItem[itemId].highestBid,
              idToAuctionItem[itemId].highestBidder, 
              itemId
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
        emit End(itemId, idToAuctionItem[itemId].highestBidder, idToAuctionItem[itemId].highestBid);
  }

  
  ///@notice This function executes the direct sale of an asset 
  ///@dev This can only be called for an item that is not on auction
  ///@param itemId The itemId of the asset to be on sold
  function directMarketSale(uint256 itemId) external nonReentrant {
    require(!idToMarketItem[itemId].isOnAuction,"Sale type is auction");  
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    require(
      tokenAddress.allowance(_msgSender(), address(this))
      >=idToMarketItem[itemId].price,"insufficient allowance"
    );
    bool transferSuccessful = tokenAddress.transferFrom(
      _msgSender(),
      address(this),
      idToMarketItem[itemId].price
    ); // transfer of funds from the buyer to the marketplace
    require(transferSuccessful,"transfer of tokens unsuccessful");
    distributionOfFundsAndAssets(idToMarketItem[itemId].price, _msgSender(), itemId);   // distribution of royalties and transfer of assets and assignment of balances shall take place
    IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
      address(this), 
      _msgSender(), 
      idToMarketItem[itemId].tokenId, 
      1, 
      "DirectSale"
    );  //Ownership transfer
    emit DirectSale(
      itemId, 
      _msgSender(), 
      owners[itemId][idToMarketItem[itemId].saleCount-1], 
      idToMarketItem[itemId].price
    );
  }
  
  ///@notice This function is called by the user to withdraw the asset purchased on the Marketplace.
  ///@dev This function is called to implement the pull payment mechanism for ERC1155 assets to avoid DOS.
  ///@param itemId The itemId of the asset purchased by the user on the Marketplace.
  function withdrawItem(uint256 itemId) external{
    require(idToMarketItem[itemId].pendingClaim==true,"cannot withdraw");
    require(idToMarketItem[itemId].owner==_msgSender(), "not your asset");
    idToMarketItem[itemId].pendingClaim=false;
    IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
      address(this), 
      _msgSender(), 
      idToMarketItem[itemId].tokenId, 
      1, 
      "AuctionWinner"
    );  //Ownership transfer
    emit WithdrawItem(itemId, _msgSender());
  }

  
  ///@notice This function executes the listing for sale of an asset previously purchased on the marketplace.
  ///@dev The approval from the nftContract is required for transferring the ownership of the asset to the marketplace contract.
  ///@param itemId The itemId of the asset to be resold
  ///@param price The price at which the item is listed for resale on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  function resellItem(uint256 itemId, uint256 price, bool isAuctionItem, uint256 numDays) external {
    require(!idToMarketItem[itemId].isOnMarket,"The Item is already on sale");
    require(_msgSender()==idToMarketItem[itemId].owner, "You are not allowed to resell");
    IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
      _msgSender(), 
      address(this), 
      idToMarketItem[itemId].tokenId, 
      1, 
      "ResellItem"
    );
    idToMarketItem[itemId].isOnMarket = true;
    idToMarketItem[itemId].isOnAuction = isAuctionItem;
    idToMarketItem[itemId].price = price;
    _itemsOffMarket.decrement();
    if(isAuctionItem){
      // solhint-disable-next-line not-rely-on-time
      idToAuctionItem[itemId] = Auction(block.timestamp+numDays, true, false, address(0), price, 0);
    }
    emit ResellItem(itemId, _msgSender(), price, isAuctionItem);
  }

  ///@notice This function is used to complete any incomplete royalty loops that had insufficient gas for execution
  ///@dev This function can only be called by the deployer and in case the gas is still not sufficient, this can be recalled and acounts for the stated condition by saving the state of its last execution.
  ///@param incompleteRoyaltyId The ID of the incomplete royalty event
  function completeRoyaltyLoop(uint incompleteRoyaltyId) external onlyOwner{
    require(!incompleteRoyalties[incompleteRoyaltyId].isComplete,"already completed");
    uint i = incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached+1;
    for (
      i; 
      i < incompleteRoyalties[incompleteRoyaltyId].saleCount - 2  && gasleft()>gasThresholdForAdminLoop;
      i++
    )
    { //royalty for intermediary owners who have not been assigned the royalty yet
      pullableAmount[owners[incompleteRoyalties[incompleteRoyaltyId].itemId][i]]+=
        incompleteRoyalties[incompleteRoyaltyId].intermediaryBalance;
      emit Balances(
        incompleteRoyalties[incompleteRoyaltyId].itemId, 
        owners[incompleteRoyalties[incompleteRoyaltyId].itemId][i], 
        2, 
        incompleteRoyalties[incompleteRoyaltyId].intermediaryBalance
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
  function withdrawFunds(address payee) external {
    require(pullableAmount[payee]>0,"No balance to withdraw");
    uint256 currentBalance = pullableAmount[payee];
    pullableAmount[payee]=0;
    bool transferSuccessful = tokenAddress.transfer(payee,currentBalance);
    require(transferSuccessful,"transfer of tokens unsuccessful");
    emit Balances(0, payee, 0, currentBalance);
  }  


  ///@notice This function is used to get the items currently on sale or auction in the marketplace.
  ///@return MarketItems currently on sale or auction in the marketplace (i.e. items with isOnMarket value stored as true).
  function fetchMarketItems() external view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsOffMarket.current();
    uint currentIndex = 0;
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 1; i <= itemCount; i++) {
      if(idToMarketItem[i].isOnMarket){
        uint currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      } 
    }
    return items;
  }

  ///@notice This function is used to get all the items in the marketplace irrespective of whether they are on sale or not.
  ///@return MarketItems in the Marketplace (irrespective of whether they are on sale or not)
  function fetchAllItems() external view returns (MarketItem[] memory) {
    MarketItem[] memory items = new MarketItem[](_itemIds.current());
    for (uint i = 0; i < _itemIds.current(); ++i){
        MarketItem storage currentItem = idToMarketItem[i+1];
        items[i] = currentItem;
    }
    return items;
  }


  ///@notice This function is used to get all the items currently owned by the msg.sender
  ///@dev This includes the items put on sale by the msg.sender too which are not currently sold
  ///@return MarketItems currently owned by the msg.sender
  function fetchMyNFTs() external view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == _msgSender()) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == _msgSender()) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  
  ///@notice This function is used to get all the items created by the msg.sender
  ///@return MarketItems created by the msg.sender
  function fetchItemsCreated() external view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (owners[i+1][0] == _msgSender()) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (owners[i+1][0] == _msgSender()) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
  

  ///@notice This function is used to get auction details of an item
  ///@param itemId The item id whose auction details are to be retrieved
  ///@return AuctionDetails of the itemId
  function fetchAuctionItemsDetails(uint256 itemId) external view returns (Auction memory) {
    return idToAuctionItem[itemId];
  }


  ///@notice This function is used to check the withdrawable balance of the user
  ///@param payee The address of the user
  ///@dev The balance is returned with the precision of the ERC20 currency
  ///@return Balance of the user
  function checkBalance(address payee) external view returns(uint256){
    return pullableAmount[payee];
  }


  ///@notice This function is called by both createMarketItem and assistedCreateMarketItem to put an asset on sale(or auction) on the Dualmint Marketplace, avoiding the duplication of code.
  ///@dev This function is an internal function.
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  ///@param assetOwner The desired owner of the item.
  function creationOfMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    bool isAuctionItem, 
    uint256 numDays, 
    address assetOwner
  ) 
    internal
  {
    require(price > 1000000, "Price must be at least 1");
    require(assets[nftContract][tokenId]==false,"asset already exists");
    assets[nftContract][tokenId] = true;
    IERC1155Upgradeable(nftContract).safeTransferFrom(
      _msgSender(), 
      address(this), 
      tokenId, 
      1, 
      "MarketItemCreated"
    ); // transfer of token ownership to marketplace contract
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
    owners[itemId][0] = assetOwner;
    if(isAuctionItem){
      // solhint-disable-next-line not-rely-on-time
      idToAuctionItem[itemId] = Auction(block.timestamp+numDays, true, false, address(0), price, 0);
    }
    emit MarketItemCreated(itemId, nftContract, tokenId, assetOwner, price, isAuctionItem);
  }


  ///@notice This function executes the royalty loop, transfer of assets, and assignment of balances
  ///@dev The unbounded loop condition is handled by storing the current state of the execution in case the gas is insufficient and can be completed by calling completeRoyaltyLoop
  ///@param price The final price at which the asset is purchased
  ///@param buyer The user about to receive the asset
  ///@param itemId The asset associated with the sale
  function distributionOfFundsAndAssets(uint price, address buyer, uint itemId) internal {
    idToMarketItem[itemId].saleCount+=1;
    uint saleCount = idToMarketItem[itemId].saleCount;
    uint256 marketplaceCommission = ((price * commissionPercent)/royaltiesPrecision);
    pullableAmount[deployer]+= marketplaceCommission; // assigning commission to the marketplace
    emit Balances(itemId, deployer, 1, marketplaceCommission);
    //allocation of sale price and royalties
    if(saleCount==1){
      // a -> b
      //if it is the first sale, the seller gets all the money
      uint256 sellerBalance = (((royaltiesPrecision-commissionPercent)*price)/royaltiesPrecision);
      pullableAmount[idToMarketItem[itemId].owner]+=sellerBalance;
      emit Balances(itemId, idToMarketItem[itemId].owner, 1, sellerBalance);
    } else if (saleCount==2){
      // a -> b -> c
      //if it is the second sale
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties)/royaltiesPrecision);
      pullableAmount[owners[itemId][0]]+= firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance);
      //seller gets the sale price ( - royalty - commission)
      uint256 sellerBalance = ((price*(royaltiesPrecision-royalties-commissionPercent))
        /royaltiesPrecision);
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]]+=sellerBalance;
      emit Balances(itemId, owners[itemId][idToMarketItem[itemId].saleCount-1], 1 ,sellerBalance);
    } else if (saleCount==3){
      // a-> b -> c -> d
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties*royaltyFirstOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][0]]+=firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance);
      // royalty to last seller
      uint256 lastOwnerBalance = ((price*royalties*(royaltiesPrecision-royaltyFirstOwner))
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-2]]+=lastOwnerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-2] , 2, lastOwnerBalance);
      //seller gets the sale price ( - royalty - commission)
      uint256 sellerBalance = ((price*(royaltiesPrecision-royalties-commissionPercent))
        /royaltiesPrecision);
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]]+=sellerBalance;
      emit Balances(itemId, owners[itemId][idToMarketItem[itemId].saleCount-1], 1 ,sellerBalance);
    } else { // this condition is hit when saleCount>3
      // a->b->c->.....->w->x->y->z
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties*royaltyFirstOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][0]]+= firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance);
      // royalty to last seller
      uint256 lastOwnerBalance = ((price*royalties*royaltyLastOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-2]]+=lastOwnerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-2] , 2, lastOwnerBalance);
      // selling price - commission given to seller
      uint256 sellerBalance = ((price*(royaltiesPrecision - royalties - commissionPercent))
        /royaltiesPrecision);
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]]+=sellerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-1], 1,  sellerBalance);
      // intermediaries get royalty
      uint256 intermediaryBalance = ((price*royalties
        *(royaltiesPrecision-royaltyFirstOwner-royaltyLastOwner))
        /(royaltiesPrecision*royaltiesPrecision))
        /(idToMarketItem[itemId].saleCount-3);
      uint i=1;
      for (i;i< idToMarketItem[itemId].saleCount-2 && gasleft()>gasThresholdForUserLoop; i++){ //royalty distributed among intermediary owners
        pullableAmount[owners[itemId][i]] += intermediaryBalance;
        emit Balances(itemId, owners[itemId][i], 2, intermediaryBalance);
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
        emit IncompleteRoyalty(royaltyId, itemId, i, idToMarketItem[itemId].saleCount);
      }
    }
    owners[itemId][idToMarketItem[itemId].saleCount]= buyer; // the new owner is _msgSender()
    idToMarketItem[itemId].isOnMarket = false;  // resetting
    idToMarketItem[itemId].owner = buyer;
    _itemsOffMarket.increment();
  }


  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}
}

