// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./ReentrancyGuard.sol";
import "./Decimals.sol";
import "./TransferHelper.sol";
import "./NFTHelper.sol";

/**
 * @title HedgeyOTC is an over the counter peer to peer trading contract
 * @notice This contract allows for a seller to generate a unique over the counter deal, which can be private or public
 * @notice The public deals allow anyone to participate and purchase tokens from the seller, whereas a private deal allows only a single whitelisted address to participate
 * @notice The Seller decides how much tokens to sell and at what price
 * @notice The Seller also decides if the tokens being sold must be time locked - which means that there is a vesting period before the buyers can access those tokens
 */
contract HedgeyOTC is ReentrancyGuard {
  using SafeERC20 for IERC20;

  /// @dev we set the WETH address so that we can wrap and unwrap ETH sending to and from the smart contract
  /// @dev the smart contract always stores WETH, but receives and delivers ETH to and from users
  address payable public weth;
  /// @dev d is a basic counter, used for indexing all of the deals - and deals are mapped to each index d
  uint256 public d = 0;
  /// @dev the futureContract is used to time lock tokens. This contract points to one specific contract for time locking
  /// @dev the futureContract is an ERC721 contract that locks the tokens for users until they are unlocked and can be redeemed
  address public futureContract;

  constructor(address payable _weth, address _fc) {
    weth = _weth;
    futureContract = _fc;
  }

  /**
   * @notice Deal is the struct that defines a single OTC offer, created by a seller
   * @dev  Deal struct contains the following parameter definitions:
   * @dev 1) seller: This is the creator and seller of the deal
   * @dev 2) token: This is the token that the seller is selling! Must be a standard ERC20 token, parameter is the contract address of the ERC20
   * @dev ... the ERC20 contract is required to have a public call function decimals() that returns a uint. This is required to price the amount of tokens being purchase
   * @dev ... by the buyer - calculating exactly how much to deliver to the seller.
   * @dev 3) paymentCurrency: This is also an ERC20 which the seller will get paid in during the act of a buyer buying tokens - also the ERC20 contract address
   * @dev 4) remainingAmount: This initially is the entire deposit the seller is selling, but as people purchase chunks of the deal, the remaining amount is decreased to 0
   * @dev 5) minimumPurchase: This is the minimum chunk size that a buyer can purchase, defined by the seller, must be greater than 0.
   * @dev 6) price: The Price is the per token cost which buyers pay to the seller, denominated in the payment currency. This is not the total price of the deal
   * @dev ... the total price is calculated by the remainingAmount * price (then adjusting for the decimals of the payment currency)
   * @dev 7) maturity: this is the unix time defining the period in which the deal is valid. After the maturity no purchases can be made.
   * @dev 8) unlockDate: this is the unix time which may be used to time lock tokens that are sold. If the unlock date is 0 or less than current block time
   * @dev ... at the time of purchase, the tokens are not locked but rather delivered directly to the buyer from the contract
   * @dev 9) buyer: this is a whitelist address for the buyer. It can either be the Zero address - which indicates that Anyone can purchase
   * @dev ... or it is a single address that only that owner of the address can participate in purchasing the tokens
   */
  struct Deal {
    address seller;
    address token;
    address paymentCurrency;
    uint256 remainingAmount;
    uint256 minimumPurchase;
    uint256 price;
    uint256 maturity;
    uint256 unlockDate;
    address buyer;
  }

  /// @dev the Deals are all mapped via the indexer d to deals mapping
  mapping(uint256 => Deal) public deals;

  receive() external payable {}

  /**
   * @notice This function is what the seller uses to create a new OTC offering
   * @notice Once this function has been completed - buyers can purchase tokens from the seller based on the price and parameters set
   * @dev this function will pull in tokens from the seller, create a new Deal struct and mapped to the current index d
   * @dev this function does not allow for taxed / deflationary tokens - as the amount that is pulled into the contract must match with what is being sent
   * @dev this function requires that the _token has a decimals() public function on its ERC20 contract to be called
   * @param _token is the ERC20 contract address that the seller is going to create the over the counter offering for
   * @param _paymentCurrency is the ERC20 contract address of the opposite ERC20 that the seller wants to get paid in when selling the token (use WETH for ETH)
   * ... this can also be used for a token SWAP - where the ERC20 address of the token being swapped to is input as the paymentCurrency
   * @param _amount is the amount of tokens that you as the seller want to sell
   * @param _min is the minimum amount of tokens that a buyer can purchase from you. this should be less than or equal to the total amount
   * @param _price is the price per token which the seller will get paid, denominated in the payment currency
   * ... if this is a token SWAP, then the _price needs to be set as the ratio of the tokens being swapped - ie 10 for 10 paymentCurrency tokens to 1 token
   * @param _maturity is how long you would like to allow buyers to purchase tokens from this deal, in unix time. this needs to be beyond current block time
   * @param _unlockDate is used if you are requiring that tokens purchased by buyers are locked. If this is set to 0 or anything less than current block time
   * ... any tokens purchased will not be locked but immediately delivered to the buyers. Otherwise the unlockDate will lock the tokens in the associated
   * ... futureContract and mint the buyer an NFT - which will hold the tokens in escrow until the unlockDate has passed - whereupon the owner of the NFT can redeem the tokens
   * @param _buyer is a special option to make this a private deal - where only a specific buyer's address can participate and make the purchase. If this is set to the
   * ... Zero address - then it is publicly available and anyone can purchase tokens from this deal
   */
  function create(
    address _token,
    address _paymentCurrency,
    uint256 _amount,
    uint256 _min,
    uint256 _price,
    uint256 _maturity,
    uint256 _unlockDate,
    address payable _buyer
  ) external payable nonReentrant {
    /// @dev check to make sure that the maturity is beyond current block time
    require(_maturity > block.timestamp, 'OTC01');
    /// @dev check to make sure that the total amount is grater than or equal to the minimum
    require(_amount >= _min, 'OTC02');
    /// @dev this checks to make sure that if someone purchases the minimum amount, it is never equal to 0
    /// @dev where someone could find a small enough minimum to purchase all of the tokens for free.
    require((_min * _price) / (10**Decimals(_token).decimals()) > 0, 'OTC03');
    /// @dev creates the Deal struct with all of the parameters for inputs - and set the bool 'open' to true so that this offer can now be purchased
    deals[d++] = Deal(msg.sender, _token, _paymentCurrency, _amount, _min, _price, _maturity, _unlockDate, _buyer);
    /// @dev pulls the tokens into this contract so that they can be purchased. If ETH is being used, it will pull ETH and wrap and receive WETH into this contract
    TransferHelper.transferPayment(weth, _token, payable(msg.sender), payable(address(this)), _amount);
    /// @dev emit an event with the parameters of the deal, because counter d has already been increased by 1, need to subtract one when emitting the event
    emit NewDeal(d - 1, msg.sender, _token, _paymentCurrency, _amount, _min, _price, _maturity, _unlockDate, _buyer);
  }

  /**
   * @notice This function lets a seller cancel their existing deal anytime they if they want to, including before the maturity date
   * @notice all that is required is that the deal has not been closed, and that there is still a reamining balance
   * @dev you need to know the index _d of the deal you are trying to close and that is it
   * @dev only the seller can close this deal
   * @dev once this has been called the Deal struct in storage is deleted so that it cannot be accessed for any further methods
   * @param _d is the dealID that is mapped to the Struct Deal
   */
  function close(uint256 _d) external nonReentrant {
    /// @dev grabs from storage the deal, and temporarily stores in memory
    Deal memory deal = deals[_d];
    /// @dev only the seller can call this function
    require(msg.sender == deal.seller, 'OTC04');
    /// @dev the remaining amount must be greater than 0
    require(deal.remainingAmount > 0, 'OTC05');
    /// @dev delete the struct so it can no longer be used
    delete deals[_d];
    /// @dev withdraw the reamining tokens to the seller (msg.sender), if its WETH send back ETH to seller
    TransferHelper.withdrawPayment(weth, deal.token, payable(msg.sender), deal.remainingAmount);
    /// @dev emit an event to announce the deal has been closed
    emit DealClosed(_d);
  }

  /**
   * @notice This function is what buyers use to make purchases from the sellers
   * @param _d is the index of the deal that a buyer wants to participate in and make a purchase
   * @param _amount is the amount of tokens the buyer is purchasing, which must be at least the minimumPurchase
   * ... and at most the remainingAmount for this deal (or the remainingAmount if that is less than the minimum)
   * @notice ensure when using this function that you are aware of the minimums, and price per token to ensure sufficient balances to make a purchase
   * @notice if the deal has an unlockDate that is beyond the current block time - no tokens will be received by the buyer, but rather they will receive
   * @notice an NFT, which represents their ability to redeem and claim the locked tokens after the unlockDate has passed
   * @notice the NFT is minted from the futureContract, where the locked tokens are delivered to and held
   * @notice the Seller will receive payment in full immediately when triggering this function, there is no lock on payments
   * @dev this function can also be used to execute a token SWAP function, where the swap is executed through this function
   */
  function buy(uint256 _d, uint256 _amount) external payable nonReentrant {
    /// @dev pull the deal details from storage, placed in memory
    Deal memory deal = deals[_d];
    /// @dev we do not let the seller sell to themselves, must be a separate buyer
    require(msg.sender != deal.seller, 'OTC06');
    /// @dev require that the deal order is still valid by checking if the block time is not passed the maturity date
    require(deal.maturity >= block.timestamp, 'OTC07');
    /// @dev if the deal had a whitelist - then require the msg.sender to be that buyer, otherwise if there was no whitelist, anyone can buy
    require(msg.sender == deal.buyer || deal.buyer == address(0x0), 'OTC08');
    /// @dev require that the amount being purchased is greater than the deal minimum, or that the amount being purchased is the entire remainder of whats left
    /// @dev AND require that the remaining amount in the deal actually equals or exceeds what the buyer wants to purchase
    require(
      (_amount >= deal.minimumPurchase || _amount == deal.remainingAmount) && deal.remainingAmount >= _amount,
      'OTC09'
    );
    /// @dev we calculate the purchase amount taking the decimals from the token first
    /// @dev then multiply the amount by the per token price, and now to get back to an amount denominated in the payment currency divide by the factor of token decimals
    uint256 decimals = Decimals(deal.token).decimals();
    uint256 purchase = (_amount * deal.price) / (10**decimals);
    /// @dev transfer the paymentCurrency purchase amount from the buyer to the seller's address. If the paymentCurrency is WETH - seller will receive ETH
    TransferHelper.transferPayment(weth, deal.paymentCurrency, msg.sender, payable(deal.seller), purchase);
    /// @dev reduce the deal remaining amount by how much was purchased
    deal.remainingAmount -= _amount;
    /// @dev emit an even signifying that the buyer has purchased tokens from the seller, what amount, and how much remains to be purchased in this deal
    emit TokensBought(_d, _amount, deal.remainingAmount);
    if (deal.unlockDate > block.timestamp) {
      /// @dev if the unlockdate is the in future, then tokens will be sent to the futureContract, and NFT minted to the buyer
      /// @dev the buyer can redeem and unlock their tokens interacting with the futureContract after the unlockDate has passed
      NFTHelper.lockTokens(futureContract, msg.sender, deal.token, _amount, deal.unlockDate);
      /// @dev emit an event that a Future, ie locked tokens event, has happened
      emit FutureCreated(msg.sender, deal.token, _amount, deal.unlockDate);
    } else {
      /// @dev if the unlockDate is in the past or now - then tokens are already unlocked and delivered directly to the buyer
      TransferHelper.withdrawPayment(weth, deal.token, payable(msg.sender), _amount);
    }
    /// @dev if the reaminder is 0, then we simply delete the storage struct Deal so that it is effectively closed
    if (deal.remainingAmount == 0) {
      delete deals[_d];
    } else {
      /// @dev if there is still a remainder - we need to update our global public deal struct in storage
      deals[_d].remainingAmount = deal.remainingAmount;
    }
  }

  /// @dev events for each function
  event NewDeal(
    uint256 _d,
    address _seller,
    address _token,
    address _paymentCurrency,
    uint256 _remainingAmount,
    uint256 _minimumPurchase,
    uint256 _price,
    uint256 _maturity,
    uint256 _unlockDate,
    address _buyer
  );
  event TokensBought(uint256 _d, uint256 _amount, uint256 _remainingAmount);
  event DealClosed(uint256 _d);
  event FutureCreated(address _owner, address _token, uint256 _amount, uint256 _unlockDate);
}
