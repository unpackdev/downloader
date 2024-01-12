// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./BancorBondingCurve.sol";
import "./HighstreetBrands.sol";

/**
  * @title ProductTokenCore
  *
  * @notice A contract containing common logic for a product token.
  *
  * @dev This contract lays the foundation for transaction computations, including
  *   bonding curve calculations and variable management. This contract does not
  *   implement any transaction logic.
  */
contract ProductTokenCore is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
  using SafeMathUpgradeable for uint256;

  /// @dev Data structure representing supplier information
  struct Supplier {
    // @dev Amount of fee owned by supplier;
    // @dev Will increase when people buy(), sell(), tradin() and decrease when supplier claim the value.
    uint256 amount;
    // @dev The wallet address of supplier
    address wallet;
  }

  /// @dev Amount of liquidity in the pool, not including the platform and supplier fee
  uint256 public reserveBalance;

  /// @dev Amount of supplier liquidity in the pool
  uint256 public tradeinReserveBalance;

  /// @dev computed from the exponential factor in the
  uint32 public reserveRatio;

  /// @dev max token count, determined by the supply of our physical product
  uint32 public maxTokenCount;

  /// @dev number of tokens burned through redeeming procedure. This will drive price up permanently
  uint32 public tradeinCount;

  /// @dev an initial value used to set an initial price. This is not included in the total supply.
  uint32 public supplyOffset;

  /// @dev Link to the Bancor Bonding Curve instance
  BancorBondingCurve public bondingCurve;

  /// @dev Link to the product nft instance
  HighstreetBrands public nft;

  /// @dev supplier information.
  Supplier private supplier;

  /// @dev platform fee.
  /// @dev 75% of fee from buy, 50% of fee from sell
  uint256 private platformFee;

  /// @dev cool down time is a interval which user should wait when sell after buy
  /// @dev it is implied that user can not sell immidiately after buy a product
  uint256 public coolDownTime;

  /// @dev brand token id
  /// @dev fixed tokenId on highstreet brand.
  uint256 public brandTokenId;

  /// @dev start time of sale
  uint256 public startTime;

  /**
  * @dev End time is the last time when user can buy and sell;
  *      it is implied that product stops after that time
  */
  mapping(uint32 => uint256) public endTime;

  /**
  * @dev a list stored cool down time of every user
  */
  mapping(address => uint256) public coolDownTimes;

  /// @dev To avoid significant precision loss due to division by "fraction of fee".
  uint256 public constant FEE_MULTIPLIER = 1e24;

  /// @dev during buy, 8% of price will be charge as fee
  uint256 public constant FEE_RATE_IN_BUY = 8e24;

  /// @dev during sell, 4% of price will be charge as fee
  uint256 public constant FEE_RATE_IN_SELL = 4e24;

  /// @dev the rate of transaction fee that brand can share for each buy
  uint256 public constant FEE_RATE_IN_BUY_BRAND = 2e24;

  /// @dev To avoid significant precision loss due to division by "fraction of fee".
  /// @dev this is 100 * FEE_MULTIPLIER
  uint256 internal constant FEE_DIVIDER = 100 * FEE_MULTIPLIER;

  /// @dev base value of bit mask that represent the endTime
  uint32 public constant FEATURE_ENDTIME_MIN = 0x0000_0001;

  /// @dev bit mask that represent the endTime of buy
  uint32 public constant FEATURE_ENDTIME_BUY = FEATURE_ENDTIME_MIN;

  /// @dev bit mask that represent the endTime of sell
  uint32 public constant FEATURE_ENDTIME_SELL = FEATURE_ENDTIME_BUY << 1;

  /// @dev bit mask that represent the endTime of tradein
  uint32 public constant FEATURE_ENDTIME_TRADEIN = FEATURE_ENDTIME_SELL << 1;

  /// @dev max value of bit mask that represent the endTime
  uint32 public constant FEATURE_ENDTIME_MAX = 0x0000_1111;


  /**
    * @dev Fired in _buy()
    *
    * @param sender an address which performed an operation, usually token buyer
    * @param price  token prices spent to bought tokens
    * @param fee amount of price in charged with according to platform fee
    */
  event Buy(address indexed sender, uint256 price, uint256 fee);

  /**
    * @dev Fired in _sell()
    *
    * @param sender an address which performed an operation, usually token seller
    * @param amount amount of tokens sold
    * @param price  amount of token prices when tokens sold
    * @param fee amount of price in charged with according to platform fee
    */
  event Sell(address indexed sender, uint32 amount, uint256 price, uint256 fee);

  /**
    * @dev Fired in _tradin()
    *
    * @param sender an address which performed an operation, usually token owner
    * @param amount amount of tokens redeemed
    * @param value value of tokens paid for supplier when redeemed
    */
  event Tradein(address indexed sender, uint32 amount, uint256 value);

  /**
    * @dev Fired in updateSupplier()
    *
    * @param supplier a new address of supplier
    */
  event UpdateSupplier(address indexed supplier);

  /**
    * @dev Fired in claimSupplier()
    *
    * @param sender an address which performed an operation, usually token suppier
    * @param amount amount of fee to deposit
    */
  event ClaimSupplierFee(address indexed sender, uint256 amount);

  /**
    * @dev Fired in claimPlatformFee()
    *
    * @param sender an address which performed an operation, usually token suppier
    * @param amount amount of fee to deposit
    */
  event ClaimPlatformFee(address indexed sender, uint256 amount);

  /**
    * @dev Fired in updateEndTime()
    *
    * @param sender an address which performed an operation, usually owner
    * @param set a variable to decide which endTime we want to set (buy, sell, tradein)
    * @param endTime a timestamp which restrict user to buy and sell product
    */
  event UpdateEndTime(address indexed sender, uint32 set, uint256 endTime);

  event UpdateStartTime(address indexed sender, uint256 startTime);

  /**
    * @dev Fired in updateCoolDownTime()
    *
    * @param sender an address which performed an operation, usually owner
    * @param coolDownTime a timestamp which restrict user to wait when sell
    */
  event UpdateCoolDownTime(address indexed sender, uint256 coolDownTime);

  /**
   * @dev initializer function.
   *
   * @param _name the name of this token
   * @param _symbol the symbol of this token
   * @param _bondingCurve bonding curve instance address
   * @param _highstreetBrands product nft instance address
   * @param _reserveRatio the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount the amount of token that will exist for this type.
   * @param _supplyOffset this amount is used to determine initial price.
   * @param _baseReserve the base amount of reserve tokens, in accordance to _supplyOffset.
   * @param _startTime end time is the starting time when user can buy and sell;
   * @param _endTime end time is the last time when user can buy and sell;
   * @param _coolDownTime cool down time is a interval which user should wait when sell after buy.
   * @param _brandTokenId fixed brand tokenId that represent certain token in Highstreet brand
   *
  */
  function __initialize(
    string memory _name,
    string memory _symbol,
    address _bondingCurve,
    address _highstreetBrands,
    uint32 _reserveRatio,
    uint32 _maxTokenCount,
    uint32 _supplyOffset,
    uint256 _baseReserve,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _coolDownTime,
    uint256 _brandTokenId
  ) public virtual initializer{
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    __ERC20_init(_name, _symbol);
    __UUPSUpgradeable_init();
    __ProductToken_init_unchained(_bondingCurve, _highstreetBrands, _reserveRatio, _maxTokenCount, _supplyOffset, _baseReserve);
    supplier.wallet = _msgSender();
    if(_endTime > 0) {
      updateEndTime(FEATURE_ENDTIME_MAX, _endTime);
    }
    if(_startTime > 0) {
      updateStartTime(_startTime);
    }
    updateCoolDownTime(_coolDownTime);
    brandTokenId = _brandTokenId;
  }

  /**
   * @dev unchained initializer function.
   *
   * @param _bondingCurve bonding curve instance address
   * @param _highstreetBrands product nft instance address
   * @param _reserveRatio the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount the amount of token that will exist for this type.
   * @param _supplyOffset this amount is used to determine initial price.
   * @param _baseReserve the base amount of reserve tokens, in accordance to _supplyOffset.
   *
  */
  function __ProductToken_init_unchained(
    address _bondingCurve,
    address _highstreetBrands,
    uint32 _reserveRatio,
    uint32 _maxTokenCount,
    uint32 _supplyOffset,
    uint256 _baseReserve
  ) internal initializer {
    require(_maxTokenCount > 0, "Invalid max token count.");
    require(_reserveRatio > 0, "Invalid reserve ratio");
    require(_bondingCurve != address(0), "invalid bc address");
    require(_highstreetBrands != address(0), "invalid nft address");

    bondingCurve = BancorBondingCurve(_bondingCurve);
    nft = HighstreetBrands(_highstreetBrands);
    reserveBalance = _baseReserve * 1e18;
    tradeinReserveBalance = _baseReserve * 1e18;
    supplyOffset = _supplyOffset;
    reserveRatio = _reserveRatio;
    maxTokenCount = _maxTokenCount;
  }

  /**
   * @dev token is inseparable and only can be integer number
   * so decimal is set to zero.
   *
  */
  function decimals() public view virtual override returns (uint8) {
      return 0;
  }


  /**
   * @dev Function to check how many tokens of this product are currently available for purchase,
   * by taking the difference between max cap count and current token in circulation or burned.
   *
   * @return available the number of tokens available
  */
  function getAvailability() public view virtual returns (uint32 available)
  {
    return maxTokenCount - uint32(totalSupply()) - tradeinCount;    // add safemath for uint32 later
  }

  /**
   * @dev Used internally, function that computes supply value for the bonding curve
   * based on current token in circulation, token offset initialized, and tokens already redeemed.
   *
   * @return supply upply value for bonding curve calculation.
  */
  function _getTotalSupply() internal view virtual returns (uint32 supply)
  {
    return uint32(totalSupply().add(uint256(tradeinCount)).add(uint256(supplyOffset)));
  }

  /**
   * @dev Function that computes current price for a token through bonding curve calculation
   * based on parameters such as total supply, reserve balance, and reserve ratio.
   *
   * @return price current price in reserve token (in our case, this is HIGH). (with 4% platform fee)
  */
  function getCurrentPrice() external view virtual returns (uint256 price)
  {
    return getPriceForN(1);
  }

  /**
   * @dev Function that computes price total for buying n token through bonding curve calculation
   * based on parameters such as total supply, reserve balance, and reserve ratio.
   *
   * @param  _amountProduct token amount in traded token
   * @return price total price in reserve token (in our case, this is HIGH). (with 4% platform fee)
  */
  function getPriceForN(uint32 _amountProduct) public view virtual returns(uint256 price)
  {
    (uint value, uint fee) = _getPriceForN(_amountProduct);
    return value.add(fee);
  }

  /**
   * @dev Used internally, mostly by getPriceForN() and _buy()
   *
   * @param _amountProduct the amount of product token
   *
   * @return price price for N product token
   * @return fee platform and supplier fee charge to the buyer
  */
  function _getPriceForN(uint32 _amountProduct) internal view virtual returns (uint256 price, uint256 fee) {
    price = bondingCurve.calculatePriceForNTokens(
                _getTotalSupply(),
                reserveBalance,
                reserveRatio,
                _amountProduct
              );
    //ppm of 96%. 4% is the platform transaction fee
    fee = price * FEE_RATE_IN_BUY / FEE_DIVIDER ;
    return (price, fee);
  }


  /**
   * @dev Used internally, mostly by calculateBuyReturn()
   *
   * @param _amountReserve the total value that the buyer would like to pay (pegged currency)
   *
   * @return amount total amount of product token that buyer can have based on _amountReserve
   * @return fee platform and supplier fee charge to the buyer
   */
  function _buyReturn(uint256 _amountReserve) internal view virtual returns (uint32 amount, uint fee)
  {
    // value should be dvided by 1.04, before purchase
    uint256 value = _amountReserve * FEE_DIVIDER / (FEE_DIVIDER + FEE_RATE_IN_BUY);
    //ppm of 96%. 4% is the platform transaction fee
    fee = value * FEE_RATE_IN_BUY / FEE_DIVIDER;

    amount = bondingCurve.calculatePurchaseReturn(
              _getTotalSupply(),
              reserveBalance,
              reserveRatio,
              value - fee
            );
    return (amount, fee);
  }

  /**
   * @dev Function that computes number of product tokens one can buy given an amount in reserve token.
   *
   * @param  _amountReserve purchaing amount in reserve token (HIGH)(with 4% platform fee)
   * @return mintAmount number of tokens in traded token that can be purchased by given amount.
  */
  function calculateBuyReturn(uint256 _amountReserve)
    external view virtual returns (uint32 mintAmount)
  {
    (uint32 amount,) = _buyReturn(_amountReserve);
    return amount;
  }

  /**
   * @dev Used internally, to computes selling price for given amount of product tokens
   *
   * @param _amountProduct amount of product token that seller would like to sell
   * @return amount of tokens(pegged currency) that seller can have
   * @return fee platform and supplier fee charge to the seller
   */
  function _sellReturn(uint32 _amountProduct)
    internal view virtual returns (uint256 amount, uint256 fee)
  {
    // ppm of 98%. 2% is the platform transaction fee
    amount = bondingCurve.calculateSaleReturn(
              _getTotalSupply(),
              reserveBalance,
              reserveRatio,
              _amountProduct
            );
    fee = amount * FEE_RATE_IN_SELL / FEE_DIVIDER;
    return (amount, fee);
  }

  /**
   * @dev Function that computes selling price in reserve tokens given an amount in traded token.
   *
   * @param  _amountProduct selling amount in product token
   * @return soldAmount total amount that will be transferred to the seller (with 2% platform fee).
  */
  function calculateSellReturn(uint32 _amountProduct) external view virtual returns (uint256 soldAmount)
  {
    (uint reimburseAmount, uint fee) = _sellReturn(_amountProduct);
    return (reimburseAmount - fee);
  }

  /**
   * @dev Used internally, for supplier to calculate the token amount they can withdraw.
   *      The value will increase when users redeem the product token
   *
   * @param _amount amount of product token wishes to be redeemed
   *
   * @return price price base on input amount
   */
  function _tradinReturn(uint32 _amount) internal view virtual returns (uint256 price)
  {
    uint32 supply = uint32(uint256(_amount).add(uint256(tradeinCount)).add(uint256(supplyOffset)));
    return bondingCurve.calculatePriceForNTokens(
            supply,
            tradeinReserveBalance,
            reserveRatio,
            _amount
          );
  }

  /**
   * @dev Used internally, calculates the return for a given conversion (in product token)
   * This function validate whether is enough to purchase token.
   * If enough, the function will deduct, and then mint one token for the user. Any extras are return as change.
   * If not enough, will return as change directly
   * then replace the _amount with the actual amount and proceed with the above logic.
   *
   * @param _deposit reserve token deposited
   *
   * @return change amount of change in reserve tokens.
  */
  function _buy(uint256 _deposit) internal virtual returns (uint256 change)
  {
    require(getAvailability() > 0, "Sorry, this token is sold out.");

    (uint price, uint fee ) = _getPriceForN(1);

    require(_deposit >= (price + fee), "Insufficient max price.");
    _mint(_msgSender(), 1);
    // 50% of fee, is for supplier
    _updateSupplierFee(fee * FEE_RATE_IN_BUY_BRAND / FEE_RATE_IN_BUY);
    // 50% of fee, is for platform
    _updatePlatformFee(fee * (FEE_RATE_IN_BUY - FEE_RATE_IN_BUY_BRAND) / FEE_RATE_IN_BUY);

    reserveBalance = reserveBalance + price;

    emit Buy(_msgSender(), price, fee);
    return (_deposit - price - fee);
  }

  /**
   * @dev Used internally, calculates the return for a given conversion (in the reserve token)
   * This function will try to compute the amount of liquidity one gets by selling _amount token,
   * then it will initiate a transfer.
   *
   * @param _amount amount of product token wishes to be sold
   *
   * @return price price returned after sold tokens
  */
  function _sell(uint32 _amount) internal virtual returns (uint256 price)
  {
    // calculate amount of liquidity to reimburse
    (uint256 reimburseAmount, uint256 fee) = _sellReturn(_amount);

    reserveBalance = reserveBalance - reimburseAmount;

    _burn(_msgSender(), _amount);

    // 50% of fee, is for supplier
    _updateSupplierFee(fee * FEE_MULTIPLIER / FEE_RATE_IN_SELL);
    // 50% of fee, is for platform
    _updatePlatformFee(fee * (FEE_RATE_IN_SELL - FEE_MULTIPLIER) / FEE_RATE_IN_SELL);

    emit Sell(_msgSender(), _amount, reimburseAmount, fee);

    return (reimburseAmount - fee);
  }

  /**
   * @dev Used internally, when user wants to trade in their token for retail product
   *
   * @param amount_ amount of product token wishes to be redeemed
   *
  */
  function _tradein(uint32 amount_) internal virtual {

    _burn(_msgSender(), amount_);
    // redeem value should give to supplier
    uint256 tradinReturn = _tradinReturn(amount_);

    //redeem value should give to supplier
    _updateSupplierFee(tradinReturn);

    nft.mint(_msgSender(), brandTokenId, amount_, "");

    tradeinCount = tradeinCount + amount_;
    tradeinReserveBalance = tradeinReserveBalance + tradinReturn;

    emit Tradein(_msgSender(), amount_, tradinReturn);
  }

  /**
   * @dev Used internally, to update the transaction fee for supplier. See _buy(), _sell, and _tradein()
   *
   * @param fee_ value to be accumulate
   */
  function _updateSupplierFee(uint256 fee_) internal virtual {
    supplier.amount = supplier.amount + fee_;
  }

  /**
   * @dev Used internally, to update the transaction fee for Highstreet. See _buy(), _sell, and _tradein()
   *
   * @param fee_ value to be accumulate
   */
  function _updatePlatformFee(uint256 fee_) internal virtual {
    platformFee = platformFee + fee_;
  }

  /**
   * @notice Update the address of supplier wallet
   *
   * @dev Only owner and supplier can call this function
   *
   * @param wallet_ supplier address
   */
  function transferSupplier( address wallet_) external virtual {
    require(_msgSender() == owner() || _msgSender() == supplier.wallet, "not allowed");
    require(wallet_!=address(0), "Address is invalid");
    supplier.wallet = wallet_;

    emit UpdateSupplier(wallet_);
  }

  /**
   * @notice Return the transaction fee for supplier
   * @dev The vlaue is included for both transaction fee and tradein value
   *
   * @return amount the token amount that supplier can withdraw
   */
  function getSupplierFee() external view virtual returns(uint256 amount){
    require(_msgSender() == owner() || _msgSender() == supplier.wallet, "not allowed");
    return supplier.amount;
  }

  /**
   * @notice For owner and supplier to check the supplier address
   * @dev Only owner and supplier can call this function
   *
   * @return the wallet address of the supplier
   */
  function getSupplierAddress() external view virtual returns(address){
    require(_msgSender() == owner() || _msgSender() == supplier.wallet, "not allowed");
    return supplier.wallet;
  }

  /**
   * @notice For the supplier to claim their transaction fee
   * @dev Only supplier can call this function
   *
   * @param amount_ the amount of token that supplier would like to withdraw
   */
  function claimSupplierFee(uint256 amount_) external virtual {
    require(_msgSender()  == supplier.wallet, "not allowed");
    require(amount_ <= supplier.amount, "amount is exceed");

    _claim(amount_);
    supplier.amount = supplier.amount - amount_;

    emit ClaimSupplierFee(_msgSender(), amount_);
  }

  /**
   * @notice Return the transaction fee for Highstreet
   * @dev Only owner can call this function
   *
   * @return amount the token amount that Highstreet can withdraw
   */
  function getPlatformFee() external view virtual returns(uint256 amount){
    require(_msgSender() == owner(), "not allowed");
    return platformFee;
  }

  /**
   * @notice For Highstreet to claim the transaction fee
   * @dev Only owner can call this function
   *
   * @param amount_ the amount of token that Highstreet would like to withdraw
   */
  function claimPlatformFee(uint256 amount_) external virtual {
    require(_msgSender() == owner(), "not allowed");
    require(amount_ <= platformFee, "amount is exceed");

    _claim(amount_);
    platformFee = platformFee - amount_;

    emit ClaimPlatformFee(_msgSender(), amount_);
  }

  /**
   * @notice Set token MaxSupply for fixed id in highstreet Brand
   *
   * @dev Only owner can call this function
   *
   * @param amount_ Max amount for tokenId
   */

  function setBrandIdMaxSupply(uint256 amount_) external onlyOwner {
    nft.setMaxSupply(brandTokenId, amount_);
  }

  /**
   * @dev Used internally, mostly by children implementations
   *
   * @param amount_ the token amount would like to claim
   */
  function _claim(uint256 amount_) internal virtual { }

  /**
  *@notice For Emergency operation like we will pause before upgrading contract
  *        thus user would not able to make trade(buy, sell, tradein)
  *@dev Only owner can call this function
  *
  */
  function pause() external onlyOwner{
    _pause();
  }

  /**
  *@notice For Emergency operation like we will pause before upgrading contract
  *        after that we will unpause, then make trade be normal
  *@dev Only owner can call this function
  *
  */
  function unpause() external onlyOwner{
    _unpause();
  }

  /**
    * @dev Testing time-dependent functionality is difficult and the best way of
    *      doing it is to override time in helper test smart contracts
    *
    * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
    */
  function now256() public view virtual returns (uint256) {
    // return current block timestamp
    return block.timestamp;
  }

  /**
  * @notice Service function to update product coolDownTime
  *
  * @dev This function can only be called by Owner 
  *
  * @param time_ an unix timestamp 
  */
  function updateCoolDownTime(uint256 time_) public virtual onlyOwner {
    coolDownTime = time_;
    emit UpdateCoolDownTime(_msgSender(), time_);
  }

  /**
  * @notice Service function to update product endtime
  *
  * @dev This function can only be called by Owner
  *
  * @param set_ a variable to decide which endTime we want to set (buy, sell, tradein
  * @param endTime_ an unix timestamp
  */
  function updateEndTime(uint32 set_, uint256 endTime_) public virtual onlyOwner {
    require(set_ <= FEATURE_ENDTIME_MAX, "invalid type");
    require(endTime_ > now256(), "invalid endTime");

    if(FEATURE_ENDTIME_BUY & set_ == FEATURE_ENDTIME_BUY) {
      endTime[FEATURE_ENDTIME_BUY] = endTime_;
    }
    if(FEATURE_ENDTIME_SELL & set_ == FEATURE_ENDTIME_SELL) {
      endTime[FEATURE_ENDTIME_SELL] = endTime_;
    }
    if(FEATURE_ENDTIME_TRADEIN & set_ == FEATURE_ENDTIME_TRADEIN) {
      endTime[FEATURE_ENDTIME_TRADEIN] = endTime_;
    }
    emit UpdateEndTime(_msgSender(), set_, endTime_);
  }

  /**
   * @notice Service function to update product endtime
   *
   * @dev This function can only be called by Owner
   *
   * @param startTime_ an unix timestamp
   */
  function updateStartTime(uint256 startTime_) public virtual onlyOwner {
    require(startTime_ > now256(), "invalid time");
    startTime = startTime_;
    emit UpdateStartTime(_msgSender(), startTime_);
  }

  /**
    * @inheritdoc ERC20Upgradeable
    *
    * @dev Additionally to the parent smart contract, add cool down time limitation
    * @dev user will not able to transfer within cool down time (for more see buy, sell, transferFrom)
    */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(now256() > coolDownTimes[_msgSender()], "wait to cool down");
    return super.transfer(recipient, amount);
  }

  /**
    * @inheritdoc ERC20Upgradeable
    *
    * @dev Additionally to the parent smart contract, add cool down time limitation
    * @dev user will not able to transferFrom within cool down time (for more see buy, sell, transfer)
    */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    require(now256() > coolDownTimes[sender], "wait to cool down");
    return super.transferFrom(sender, recipient, amount);
  }

  /**
    * @dev  See {UUPSUpgradeable-_authorizeUpgrade}.
    *
    */
  function _authorizeUpgrade(address) internal override onlyOwner {}

  fallback () external { }
}

