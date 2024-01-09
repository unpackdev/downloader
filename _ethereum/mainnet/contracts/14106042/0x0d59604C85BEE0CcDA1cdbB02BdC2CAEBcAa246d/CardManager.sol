// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./CardBase.sol";
import "./CardNft.sol";
import "./PriceConsumerV3.sol";

contract CardManager is PriceConsumerV3, CardBase, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Receive the fund collected
  address payable public _beneficiary;

  uint256 public _totalAvaTokensCollected;
  uint256 public _totalNativeTokensCollected;

  // AVA token
  IERC20 public _avaToken;

  // CardNft contract
  CardNft public _cardNft;

  // "decimals" is 18 for AVA tokens
  uint256 constant E18 = 10**18;

  uint256 public _cardPriceUsdCent;
  uint256 public _maxSupplyForSale = 900;

  bool public _purchaseInAvaEnabled = false;

  // Keep current number of minted cards
  uint256 public _cardNumForSaleMinted;

  uint256 public _giveBackToCommunityPercent = 0;
  address payable public _communityPoolWallet;

  uint256 public _discountWhenBuyInAvaPercent = 5;

  // Update frequently by external background service
  uint256 public _avaTokenPriceInUsdCent; // 300 == 3 USD (i.e. 1 AVA costs 3 USD)

  // Max allowable cards per wallet address for private sale depending on smart level
  mapping(address => uint256) public _maxAllowableCardsForPrivateSale;
  bool public _privateSaleEnabled = true;
  // Max allowable cards per wallet address for public sale
  uint256 public _maxAllowableCardsForPublicSale = 1;
  // Keep track of the number of minted cards per wallet address
  mapping(address => uint256) public _cardNumPerWalletMinted;

  event EventBuyInAva(
    address buyer_,
    uint256[] mintedTokenIdList_,
    uint256 cardAmount_,
    uint256 totalAvaTokensToPay_
  );
  event EventBuyInNative(
    address buyer_,
    uint256[] mintedTokenIdList_,
    uint256 cardAmount_,
    uint256 totalToPay_
  );

  event EventMintAfterPayment(
    address buyer_,
    address minter_,
    uint256[] mintedTokenIdList_,
    uint256 cardAmount_
  );

  constructor(
    address avaTokenAddress_,
    address cardNftAddress_,
    address beneficiary_
  ) {
    require(
      avaTokenAddress_ != address(0),
      "CardManager: Invalid avaTokenAddress_ address"
    );

    require(
      cardNftAddress_ != address(0),
      "CardManager: Invalid cardNftAddress_ address"
    );

    require(
      beneficiary_ != address(0),
      "CardManager: Invalid beneficiary_ address"
    );

    _avaToken = IERC20(avaTokenAddress_);
    _cardNft = CardNft(cardNftAddress_);
    _beneficiary = payable(beneficiary_);
  }

  // Check if a wallet address can still buy depending on its number of minted cards
  function checkIfCanBuy(address wallet_, uint256 cardAmount_)
    public
    view
    returns (bool)
  {
    require(
      (_cardNumForSaleMinted + cardAmount_) <= _maxSupplyForSale,
      "CardManager: Max supply for sale exceed"
    );

    if (_privateSaleEnabled) {
      require(
        _maxAllowableCardsForPrivateSale[wallet_] > 0,
        "CardManager: Not whitelisted wallet for private sale"
      );

      require(
        (_cardNumPerWalletMinted[wallet_] + cardAmount_) <=
          _maxAllowableCardsForPrivateSale[wallet_],
        "CardManager: max allowable cards per wallet for private sale exceed"
      );
    } else {
      require(
        (_cardNumPerWalletMinted[wallet_] + cardAmount_) <=
          _maxAllowableCardsForPublicSale,
        "CardManager: max allowable cards per wallet for public sale exceed"
      );
    }

    return true;
  }

  ////////// Start setter /////////

  // Set basic info to start the card sale
  function setCardSaleInfo(
    uint256 cardPriceUsdCent_,
    uint256 maxSupplyForSale_,
    uint256 giveBackToCommunityPercent_,
    uint256 avaTokenPriceInUsdCent_,
    uint256 discountWhenBuyInAvaPercent_,
    address communityPoolWallet_
  ) external isOwner {
    setCardPriceUsdCent(cardPriceUsdCent_);
    setMaxSupplyForSale(maxSupplyForSale_);
    setGiveBackToCommunityPercent(giveBackToCommunityPercent_);
    setAvaTokenPriceInUsdCent(avaTokenPriceInUsdCent_);
    setDiscountWhenBuyInAvaPercent(discountWhenBuyInAvaPercent_);
    setCommunityPoolWallet(communityPoolWallet_);
  }

  function setCardPriceUsdCent(uint256 cardPriceUsdCent_) public isOwner {
    require(cardPriceUsdCent_ > 0, "CardManager: Invalid cardPriceUsdCent_");

    _cardPriceUsdCent = cardPriceUsdCent_;
  }

  function setPurchaseInAvaEnabled(bool purchaseInAvaEnabled_)
    external
    isOwner
  {
    _purchaseInAvaEnabled = purchaseInAvaEnabled_;
  }

  function setMaxSupplyForSale(uint256 maxSupplyForSale_) public isOwner {
    require(maxSupplyForSale_ > 0, "CardManager: Invalid maxSupplyForSale_");

    _maxSupplyForSale = maxSupplyForSale_;
  }

  function setGiveBackToCommunityPercent(uint256 giveBackToCommunityPercent_)
    public
    isOwner
  {
    // giveBackToCommunityPercent_ can be zero
    _giveBackToCommunityPercent = giveBackToCommunityPercent_;
  }

  function setCommunityPoolWallet(address communityPoolWallet_) public isOwner {
    // communityPoolWallet_ can be address(0)
    _communityPoolWallet = payable(communityPoolWallet_);
  }

  function setDiscountWhenBuyInAvaPercent(uint256 discountWhenBuyInAvaPercent_)
    public
    isOwner
  {
    // discountWhenBuyInAvaPercent_ can be zero
    _discountWhenBuyInAvaPercent = discountWhenBuyInAvaPercent_;
  }

  function setAvaTokenPriceInUsdCent(uint256 avaTokenPriceInUsdCent_)
    public
    isAuthorized
  {
    // avaTokenPriceInUsdCent_ can be zero
    _avaTokenPriceInUsdCent = avaTokenPriceInUsdCent_;
  }

  function setBeneficiary(address beneficiary_) external isOwner {
    require(
      beneficiary_ != address(0),
      "CardManager: Invalid beneficiary_ address"
    );
    _beneficiary = payable(beneficiary_);
  }

  function setPrivateSaleEnabled(bool privateSaleEnabled_) external isOwner {
    _privateSaleEnabled = privateSaleEnabled_;
  }

  function setMaxAllowableCardsForPrivateSale(
    address wallet_,
    uint256 maxCards_
  ) public isAuthorized {
    require(wallet_ != address(0), "CardManager: Invalid wallet_ address");

    // Do we need this 15?
    // require(maxCards_ <= 15, "CardManager: Invalid maxCards_");

    _maxAllowableCardsForPrivateSale[wallet_] = maxCards_;
  }

  function batchSetMaxAllowableCardsForPrivateSale(
    address[] memory walletList_,
    uint256[] memory maxCardsList_
  ) external isAuthorized {
    require(
      walletList_.length == maxCardsList_.length,
      "CardManager: walletList_ and maxCardsList_ do not have same length"
    );

    for (uint256 i = 0; i < walletList_.length; i++) {
      setMaxAllowableCardsForPrivateSale(walletList_[i], maxCardsList_[i]);
    }
  }

  function setMaxAllowableCardsForPublicSale(
    uint256 maxAllowableCardsForPublicSale_
  ) external isOwner {
    require(
      maxAllowableCardsForPublicSale_ > 0,
      "CardManager: Invalid maxAllowableCardsForPublicSale_"
    );

    _maxAllowableCardsForPublicSale = maxAllowableCardsForPublicSale_;
  }

  ////////// End setter /////////

  function getCardSaleInfo()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      address
    )
  {
    return (
      _cardPriceUsdCent,
      _maxSupplyForSale,
      _giveBackToCommunityPercent,
      _avaTokenPriceInUsdCent,
      _discountWhenBuyInAvaPercent,
      _communityPoolWallet
    );
  }

  // Get price of ETH or BNB
  function getNativeCoinPriceInUsdCent() public view returns (uint256) {
    uint256 nativeCoinPriceInUsdCent = uint256(getCurrentPrice()) * 100;
    return nativeCoinPriceInUsdCent;
  }

  // Get card price in AVA tokens depending on the current price of AVA
  function getCardPriceInAvaTokens() public view returns (uint256) {
    uint256 cardPriceInAvaTokens = (_cardPriceUsdCent * E18) /
      _avaTokenPriceInUsdCent;

    return cardPriceInAvaTokens;
  }

  // Buy card in AVA tokens
  function buyInAva(uint256 cardAmount_)
    external
    whenNotPaused
    nonReentrant
    returns (uint256[] memory)
  {
    require(_purchaseInAvaEnabled, "CardManager: buy in AVA disabled");

    require(cardAmount_ > 0, "CardManager: invalid cardAmount_");

    require(
      _avaTokenPriceInUsdCent > 0,
      "CardManager: AVA token price not set"
    );

    require(_cardPriceUsdCent > 0, "CardManager: invalid card price");

    uint256 cardPriceInAvaTokens = getCardPriceInAvaTokens();
    uint256 totalAvaTokensToPay = cardPriceInAvaTokens * cardAmount_;

    if (_discountWhenBuyInAvaPercent > 0) {
      totalAvaTokensToPay =
        totalAvaTokensToPay -
        ((totalAvaTokensToPay * _discountWhenBuyInAvaPercent) / 100);
    }

    // Check if user balance has enough tokens
    require(
      totalAvaTokensToPay <= _avaToken.balanceOf(_msgSender()),
      "CardManager: user balance does not have enough AVA tokens"
    );

    // Check if can buy
    checkIfCanBuy(_msgSender(), cardAmount_);

    // Transfer tokens from user wallet to beneficiary or communityPool
    uint256 giveBack = (totalAvaTokensToPay * _giveBackToCommunityPercent) /
      100;
    _avaToken.safeTransferFrom(
      _msgSender(),
      _beneficiary,
      totalAvaTokensToPay - giveBack
    );
    if (giveBack > 0 && _communityPoolWallet != address(0)) {
      _avaToken.safeTransferFrom(_msgSender(), _communityPoolWallet, giveBack);
    }

    _totalAvaTokensCollected += totalAvaTokensToPay;

    // Mint card
    uint256[] memory mintedTokenIdList = new uint256[](cardAmount_);

    if (cardAmount_ > 1) {
      mintedTokenIdList = _cardNft.mintCardMany(_msgSender(), cardAmount_);
    } else {
      uint256 mintedTokenId = _cardNft.mintCard(_msgSender());
      mintedTokenIdList[0] = mintedTokenId;
    }

    _cardNumPerWalletMinted[_msgSender()] += cardAmount_;
    _cardNumForSaleMinted += cardAmount_;

    emit EventBuyInAva(
      _msgSender(),
      mintedTokenIdList,
      cardAmount_,
      totalAvaTokensToPay
    );

    return mintedTokenIdList;
  }

  function getCardPriceInNative() public view returns (uint256) {
    uint256 nativeCoinPriceInUsdCent = getNativeCoinPriceInUsdCent();

    uint256 cardPriceInNative = (_cardPriceUsdCent * E18) /
      nativeCoinPriceInUsdCent;

    return cardPriceInNative;
  }

  // Buy card in native coins (ETH or BNB)
  function buyInNative(uint256 cardAmount_)
    external
    payable
    whenNotPaused
    nonReentrant
    returns (uint256[] memory)
  {
    require(cardAmount_ > 0, "CardManager: invalid cardAmount_");

    require(_cardPriceUsdCent > 0, "CardManager: invalid card price");

    uint256 cardPriceInNative = getCardPriceInNative();
    uint256 totalToPay = cardPriceInNative * cardAmount_;

    // Check if user-transferred amount is enough
    require(
      msg.value >= totalToPay,
      "CardManager: user-transferred amount not enough"
    );

    // Check if can buy
    checkIfCanBuy(_msgSender(), cardAmount_);

    // Transfer msg.value from user wallet to beneficiary
    uint256 giveBack = (msg.value * _giveBackToCommunityPercent) / 100;
    _beneficiary.transfer(msg.value - giveBack);
    if (giveBack > 0 && _communityPoolWallet != address(0)) {
      _communityPoolWallet.transfer(giveBack);
    }

    _totalNativeTokensCollected += msg.value;

    // Mint card
    uint256[] memory mintedTokenIdList = new uint256[](cardAmount_);

    if (cardAmount_ > 1) {
      mintedTokenIdList = _cardNft.mintCardMany(_msgSender(), cardAmount_);
    } else {
      uint256 mintedTokenId = _cardNft.mintCard(_msgSender());
      mintedTokenIdList[0] = mintedTokenId;
    }

    _cardNumPerWalletMinted[_msgSender()] += cardAmount_;
    _cardNumForSaleMinted += cardAmount_;

    emit EventBuyInNative(
      _msgSender(),
      mintedTokenIdList,
      cardAmount_,
      msg.value
    );

    return mintedTokenIdList;
  }

  // Mint card(s) after having verified user's payment (e.g. via internal wallet)
  // Can only be called by authorized wallet managed by BE
  function mintAfterPayment(address buyer_, uint256 cardAmount_)
    external
    whenNotPaused
    isAuthorized
    returns (uint256[] memory)
  {
    require(cardAmount_ > 0, "CardManager: invalid cardAmount_");
    require(buyer_ != address(0), "CardManager: invalid buyer_");

    // Check if can buy
    checkIfCanBuy(buyer_, cardAmount_);

    // Mint card
    uint256[] memory mintedTokenIdList = new uint256[](cardAmount_);

    if (cardAmount_ > 1) {
      mintedTokenIdList = _cardNft.mintCardMany(buyer_, cardAmount_);
    } else {
      uint256 mintedTokenId = _cardNft.mintCard(buyer_);
      mintedTokenIdList[0] = mintedTokenId;
    }

    _cardNumPerWalletMinted[buyer_] += cardAmount_;
    _cardNumForSaleMinted += cardAmount_;

    emit EventMintAfterPayment(
      buyer_,
      _msgSender(),
      mintedTokenIdList,
      cardAmount_
    );

    return mintedTokenIdList;
  }

  // BNB price when running on BSC or ETH price when running on Ethereum
  function getCurrentPrice() public view returns (int256) {
    return getThePrice() / 10**8;
  }
}
