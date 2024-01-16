// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Address.sol";
import "./AggregatorV3Interface.sol";
import "./IERC721Enumerable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./Seed.sol";
import "./EnumerableSet.sol";

contract CasinoRudeKidzTransferer is Ownable, Pausable {
  using Address for address payable;
  using EnumerableSet for EnumerableSet.UintSet;

  // Rude Kidz contract 
  // Rude Kidz contract implements the ERC721Enumerable interface
  IERC721Enumerable public immutable rudeKidzContract; 
  // Lugh (EURL) contract
  IERC20 public immutable lughContract;

  // The address that will receive the funds
  address public fundsRecipient;
  // Token IDs of the tokens available for sale
  EnumerableSet.UintSet private tokensForSale;

  // Price feed of EUR/USD
  AggregatorV3Interface private immutable eurToUsdFeed;
  // Price feed of ETH/USD
  AggregatorV3Interface private immutable ethToUsdFeed;
  // Price in Euro with 2 decimals
  uint256 private priceInEuro = 20000;

  Seed public immutable randomSource;

  constructor(
    address _eurToUsdFeed, 
    address _ethToUsdFeed, 
    address _rudeKidzContract, 
    address _lughContract
  ) {
    eurToUsdFeed = AggregatorV3Interface(_eurToUsdFeed);
    ethToUsdFeed = AggregatorV3Interface(_ethToUsdFeed);
    rudeKidzContract = IERC721Enumerable(_rudeKidzContract);
    lughContract = IERC20(_lughContract);

    randomSource = new Seed();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
    * @notice Buy a Rude Kidz with ETH and will receive the next
    * available token if any
    * @param _to The address that will receive the NFT
   */
  function buyWithETH(address _to) external payable whenNotPaused {
    uint256 price = getTokenPriceInETH();
    // Allow for a 0.5% difference
    uint256 minPrice = (price * 995) / 1000;
    uint256 maxPrice = (price * 1005) / 1000;
    // Check the price is within a reasonable range
    require(msg.value >= minPrice, "Not enough ETH");
    require(msg.value <= maxPrice, "Too much ETH");
    // Get the next available token ID
    // Will revert if there are no tokens left
    uint256 tokenId = getNextAvailableTokenId();
    // Gets the owner of the token
    address tokensHolder = rudeKidzContract.ownerOf(tokenId);
    // Transfer the token to the buyer
    // Tokens holder must have approved this contract to transfer the tokens
    rudeKidzContract.transferFrom(tokensHolder, _to, tokenId);
  }

  /**
    * @notice Buy a Rude Kidz with Lugh (EURL) and will receive the next
    * available token if any
    * @param _to The address that will receive the NFT
   */
  function buyWithEURL(address _to) external whenNotPaused {
    uint256 senderBalance = lughContract.balanceOf(msg.sender);
    // Add the missing 4 decimals as priceInEuro only has 2 decimals
    // and EURL has 6 decimals in total
    uint256 price = priceInEuro * 10 ** 4;
    require(senderBalance >= price, "Not enough EURL");
    // Get the next available token ID
    // Will revert if there are no tokens left
    uint256 tokenId = getNextAvailableTokenId();
    // Gets the owner of the token
    address tokensHolder = rudeKidzContract.ownerOf(tokenId);
    // Sender must have approved this contract to transfer EURL
    lughContract.transferFrom(msg.sender, address(this), price);
    // Transfer the token to the buyer
    // Tokens holder must have approved this contract to transfer the tokens
    rudeKidzContract.transferFrom(tokensHolder, _to, tokenId);
  }

  /**
    * @notice Toggle whether the sales is enabled for the given token ids
    * @param _tokenIds The token ids to toggle
    * @param _enable Whether the sales is enabled for the given token ids
    */
  function toggleTokenSales(uint256[] memory _tokenIds, bool _enable) external onlyOwner {
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      if(_enable) {
        // If enable then add it to the set
        tokensForSale.add(_tokenIds[i]);
      } else {
        // If not then remove it from the set if it exists
        tokensForSale.remove(_tokenIds[i]);
      }
    }
  }

  /**
    * @notice Set the price in Euro with 2 decimals
    * @param _priceInEuro The price in Euro with 2 decimals
    */
  function setPriceInEuro(uint256 _priceInEuro) external onlyOwner {
    priceInEuro = _priceInEuro;
  }

  /**
    * @notice Set the address that can receive the funds
    * @param _fundsRecipient The address that will receive the funds
    */
  function setFundsRecipient(address _fundsRecipient) external onlyOwner {
    require(_fundsRecipient != address(0), "Invalid address");
    fundsRecipient = _fundsRecipient;
  }

  /**
    * @notice Withdraw all the ETH and EURL deposited on this contract
    */
  function withdrawFunds() external onlyOwner {
    uint256 ethBalance = address(this).balance;
    uint256 lughBalance = lughContract.balanceOf(address(this));
    // Check that there is either ETH or EURL to withdraw
    require(ethBalance > 0 || lughBalance > 0, "No funds to withdraw");
    if (ethBalance > 0) {
      // Transfer the ETH to the funds recipient
      payable(fundsRecipient).sendValue(ethBalance);
    }
    if (lughBalance > 0) {
      // Transfer the EURL to the funds recipient
      lughContract.transfer(fundsRecipient, lughBalance);
    }
  }

  /**
    * @notice Get the id of the next token available for sale
    */
  function getNextAvailableTokenId() private returns (uint256) {
    uint256 balance = tokensForSale.length();
    // Check if the tokens holder has tokens
    require(balance > 0, "No tokens left");
    // Get a random index to get the token id at a random position
    // in the set of available tokens
    uint256 randomIndex = random(balance) % balance;
    // Update the source of randomness
    randomSource.update(balance ^ randomIndex);
    // The index value to loop through the array of tokens
    uint256 tokenId = tokensForSale.at(randomIndex);
    // Remove the token from the set of available tokens
    tokensForSale.remove(tokenId);
    return tokenId;
  }

  /**
    * @notice Get current rate of Ether to US Dollar
    */
  function getETHtoUSDPrice() private view returns (uint256) {
    (, int256 price, , , ) = ethToUsdFeed.latestRoundData();
    return uint256(price);
  }

  /**
    * @notice Get current rate of Euro to US Dollar
    */
  function getEURToUSDPrice() private view returns (uint256) {
    (, int256 price, , , ) = eurToUsdFeed.latestRoundData();
    return uint256(price);
  }

  /**
    * @notice Get the current price in ETH according
    * to a fixed price in Euro
    */
  function getTokenPriceInETH() public view returns (uint256) {
    // Get rate for EUR/USD
    uint256 eurToUsd = getEURToUSDPrice();
    // Get rate for ETH/USD
    uint256 ethToUsd = getETHtoUSDPrice();
    // Convert price in US Dollar
    // We divide by 10 to power of the number of decimals of EUR/USD feed
    // to cancel out all decimals in priceInUsd plus the 2 decimals in priceInEuro
    uint256 priceInUsd = (priceInEuro * eurToUsd) / 10**(eurToUsdFeed.decimals() + 2);
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
   * @notice Get the price in Euro, which is a fixed price
   */
  function getTokenPriceInEuro() public view returns (uint256) {
    return priceInEuro;
  }

  /**
   * @notice Generates a pseudorandom number
   */
  function random(uint256 seed) private view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
          )
        )
      ) ^ randomSource.seed();
  }

  /**
   * @notice Returns if the given token id is available for sale
   */
  function isTokenAvailableForSale(uint256 _tokenId) public view returns (bool) {
    return tokensForSale.contains(_tokenId);
  }

  /**
   * @notice Returns the number of tokens available for sale
   */
  function getTotalTokensAvailableForSale() public view returns (uint256) {
    return tokensForSale.length();
  }
}