// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC721Burnable.sol";
import "./AggregatorV3Interface.sol";
import "./ERC721URIStorage.sol";

contract PBWSStand is ERC721, Ownable, ERC721URIStorage, ERC721Burnable {
  using Address for address payable;

  // The date after which the NFT can be transfered normally
  uint256 public unlockDate;
  // Addresses that can be used as target for transfers of
  // tokens before the unlock date
  // Token id => Address => Allowed or not
  mapping(uint256 => mapping(address => bool)) private idToAllowedAddresses;
  // Token id => price of the token
  mapping(uint256 => uint256) private idToPrice;

  // Price feed of EUR/USD (8 decimals)
  AggregatorV3Interface internal immutable eurToUsdFeed;
  // Price feed of ETH/USD (8 decimals)
  AggregatorV3Interface internal immutable ethToUsdFeed;

  // The two NFTs that can be minted
  uint256 private constant PBWS_PLATINUM_ID = 0;
  uint256 private constant NFT_DAYS_ID = 1;

  address public immutable pbwsAddress;
  address public constant teamAddress =
    0x5F5D71bf86b805Ae3f3df27B43EBa3A8F3Caf18A;
  address public immutable artistAddress;

  // The commission for the artist from 0 to 1000 (i.e. 115 is 11.5%)
  uint16 private artistCommission = 100;

  bool public canBuy;

  constructor(
    uint256 _unlockDate,
    address _pbwsAddress,
    address _artistAddress,
    address eurToUsdPriceFeed,
    address ethToUsdPriceFeed
  ) ERC721("PBWS Stand", "PBWSS") {
    unlockDate = _unlockDate;

    ethToUsdFeed = AggregatorV3Interface(ethToUsdPriceFeed);
    eurToUsdFeed = AggregatorV3Interface(eurToUsdPriceFeed);
    // PBWS Platinum Stand price in Euro
    idToPrice[PBWS_PLATINUM_ID] = 90000;
    // NFT Day Stand price in Euro
    idToPrice[NFT_DAYS_ID] = 80000;

    // Set the addresses
    pbwsAddress = _pbwsAddress;
    artistAddress = _artistAddress;

    // Mint the two NFTs straight away on deployment
    _safeMint(address(this), PBWS_PLATINUM_ID);
    _safeMint(address(this), NFT_DAYS_ID);
  }

  /**
   * @dev Transfer a stable coin pegged to USD (DAI, USDT or USDC) to this
   * contract as payment for the token purchased. The token bought is then
   * transfered to the sender.
   * Calling this function requires that the sender has first approved this
   * contract with a sufficient allowance of the stable coin they wish to use
   * @param tokenId The id of the token to buy
   * @param allowedAddrs Addresses that can be a target for transfers
   * before the unlock date is reached
   * @param includeVAT Whether to include the French VAT for French residents
   */
  function buy(
    uint256 tokenId,
    address[] memory allowedAddrs,
    bool includeVAT
  ) external payable {
    require(_exists(tokenId), "Nonexistent token");

    require(canBuy, "Purchase not enabled");
    // Check that the token has not already purchased
    // (i.e. the contract doesn't own it)
    require(ownerOf(tokenId) == address(this), "Already purchased");

    uint256 priceInWei = getTokenPriceInETH(tokenId);
    if (includeVAT) {
      // Add a 20% tax to take into account the VAT
      priceInWei = (priceInWei * 120) / 100;
    }

    uint256 minPrice = (priceInWei * 995) / 1000;
    uint256 maxPrice = (priceInWei * 1005) / 1000;
    // The sender should provide enough ETH to pay for the token
    // And we make sure that the value is within an acceptable range
    // of the actual price
    require(msg.value >= minPrice, "Not enough ETH");
    require(msg.value <= maxPrice, "Too much ETH");

    // Transfer the token to the buyer
    this.safeTransferFrom(address(this), msg.sender, tokenId);
    // Add the addresses allowed to be set as a target for
    // transfer before the unlocking date
    for (uint256 i = 0; i < allowedAddrs.length; i++) {
      idToAllowedAddresses[tokenId][allowedAddrs[i]] = true;
    }
  }

  /**
   * @dev Allow to set the price of a given token
   */
  function setTokenPrice(uint256 tokenId, uint256 priceInEuro)
    external
    onlyOwner
  {
    idToPrice[tokenId] = priceInEuro;
  }

  /**
   * @dev Set the date after which the token transfers will be fully unlocked
   */
  function setUnlockDate(uint256 date) external onlyOwner {
    unlockDate = date;
  }

  /**
   * @dev Set the token URI for a given token
   */
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    external
    onlyOwner
  {
    _setTokenURI(tokenId, _tokenURI);
  }

  /**
   * @dev Toggle the purchase status
   * (true = can purchase a token, false = cannot purchase a token)
   */
  function togglePurchase() external onlyOwner {
    canBuy = !canBuy;
  }

  /**
   * @dev Set the commission for the artist
   */
  function setArtistRoyalty(uint16 commission) external onlyOwner {
    artistCommission = commission;
  }

  /**
   * @dev Retrieve the funds received from the sale of the tokens
   */
  function retrieveFunds() external {
    // Only the owner, PBWS address or the team can call this function
    require(
      msg.sender == pbwsAddress ||
        msg.sender == owner() ||
        msg.sender == teamAddress,
      "Not allowed"
    );

    // Get the entire balance held by the contract
    uint256 totalBalance = address(this).balance;
    // PBWS retrieve 80% of the funds minus the commission meant for the artist
    uint256 pbwsBalance = (totalBalance * (800 - artistCommission)) / 1000;
    // Send the funds meant for PBWS
    payable(pbwsAddress).sendValue(pbwsBalance);
    // The artist retrieve their commission
    uint256 artistBalance = (totalBalance * artistCommission) / 1000;
    // Send the funds meant for the artist
    payable(artistAddress).sendValue(artistBalance);
    // The team who developed this smart contract gets 20% of the funds
    uint256 teamBalance = (totalBalance * 20) / 100;
    // Send the funds meant for the team
    payable(teamAddress).sendValue(teamBalance);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    // If the unlock date is not passed yet, if we're not minting a new
    // token and if we're not transfering from this contract to the holder,
    // we check if the target address is allowed
    if (
      to != address(0) &&
      from != address(0) &&
      from != address(this) &&
      block.timestamp < unlockDate
    ) {
      require(idToAllowedAddresses[tokenId][to], "Target address not allowed");
    } else {
      // We block the transfer before the unlock date unless the target is allowed
      require(
        block.timestamp >= unlockDate ||
          from == address(0) ||
          from == address(this),
        "Transfer not allowed"
      );
    }
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // The following functions are overrides required by Solidity.
  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  /**
  @dev Get current rate of Ether to US Dollar
   */
  function getETHtoUSDPrice() private view returns (uint256) {
    (, int256 price, , , ) = ethToUsdFeed.latestRoundData();
    return uint256(price);
  }

  /**
   * @dev Get current rate of Euro to US Dollar
   */
  function getEURToUSDPrice() private view returns (uint256) {
    (, int256 price, , , ) = eurToUsdFeed.latestRoundData();
    return uint256(price);
  }

  /**
   * @dev Get the current price of the token in ETH according
   * to a fixed price in Euro
   */
  function getTokenPriceInETH(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Nonexistent token");
    // Get the price fixed in Euro for the token
    uint256 priceInEuro = idToPrice[tokenId];
    // Get rate for EUR/USD
    uint256 eurToUsd = getEURToUSDPrice();
    // Get rate for ETH/USD
    uint256 ethToUsd = getETHtoUSDPrice();
    // Convert price in US Dollar
    // We divide by 10 to power of the number of decimals of EUR/USD feed
    // to cancel out all decimals in priceInUsd
    uint256 priceInUsd = (priceInEuro * eurToUsd) / 10**eurToUsdFeed.decimals();
    // Convert price in Ether for US Dollar price
    // We multiply by the 10^(decimals of ETH/USD feed) to make the priceInUsd
    // which has no decimals equal to the number of decimals of the denominator
    // We then multiply by 10^18 to increase the accuracy of the conversion
    // and also make the result 18 decimals (so denominated in Wei) since the rest
    // of the decimals cancel out between numerator and denominator
    uint256 priceInEth = (priceInUsd * 10**(ethToUsdFeed.decimals()) * 10**18) /
      ethToUsd;
    return priceInEth;
  }

  /**
   * @dev Get the price of the token in Euro, which is a fixed price
   */
  function getTokenPriceInEuro(uint256 tokenId) public view returns (uint256) {
    require(_exists(tokenId), "Nonexistent token");
    return idToPrice[tokenId];
  }
}
