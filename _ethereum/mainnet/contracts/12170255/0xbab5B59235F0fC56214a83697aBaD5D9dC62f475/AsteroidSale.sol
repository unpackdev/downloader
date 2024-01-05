// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./IAsteroidToken.sol";
import "./IAsteroidFeatures.sol";
import "./IAsteroidScans.sol";


/**
 * @dev Contract that controls the initial sale of Asteroid tokens
 */
contract AsteroidSale is Ownable {
  IAsteroidToken token;
  IAsteroidFeatures features;
  IAsteroidScans scans;
  uint64 public saleStartTime; // in seconds since epoch
  uint64 public saleEndTime; // in seconds since epoch
  uint public baseAsteroidPrice;
  uint public baseLotPrice;

  event SaleCreated(uint64 indexed start, uint64 end, uint asteroidPrice, uint lotPrice);
  event SaleCancelled(uint64 indexed start);

  /**
   * @param _token Reference to the AsteroidToken contract address
   * @param _features Reference to the AsteroidFeatures contract address
   */
  constructor(IAsteroidToken _token, IAsteroidFeatures _features, IAsteroidScans _scans) {
    token = _token;
    features = _features;
    scans = _scans;
  }

  /**
   * @dev Sets the initial parameters for the sale
   * @param _startTime Seconds since epoch to start the sale
   * @param _duration Seconds for the sale to run starting at _startTime
   * @param _perAsteroid Price in wei per asteroid
   * @param _perLot Additional price per asteroid multiplied by the surface area of the asteroid
   */
  function setSaleParams(uint64 _startTime, uint64 _duration, uint _perAsteroid, uint _perLot) external onlyOwner {
    require(_startTime > saleEndTime + 86400, "Next sale must start at least 1 day after the previous");
    require(_startTime >= block.timestamp, "Sale must start in the future");
    require(_duration >= 86400, "Sale must last for at least 1 day");
    saleStartTime = _startTime;
    saleEndTime = _startTime + _duration;
    baseAsteroidPrice = _perAsteroid;
    baseLotPrice = _perLot;
    emit SaleCreated(saleStartTime, saleEndTime, baseAsteroidPrice, baseLotPrice);
  }

  /**
   * @dev Cancels a future or ongoing sale
   **/
  function cancelSale() external onlyOwner {
    emit SaleCancelled(saleStartTime);
    saleStartTime = 0;
    saleEndTime = 0;
  }

  /**
   * @dev Retrieve the price for the given asteroid which includes a base price and a price scaled by surface area
   * @param _tokenId ERC721 token ID of the asteroid
   */
  function getAsteroidPrice(uint _tokenId) public view returns (uint) {
    require(baseAsteroidPrice > 0 && baseLotPrice > 0, "Base prices must be set");
    uint radius = features.getRadius(_tokenId);
    uint lots = (radius * radius) / 250000;
    return baseAsteroidPrice + (baseLotPrice * lots);
  }

  /**
   * @dev Purchase an asteroid
   * @param _tokenId ERC721 token ID of the asteroid
   **/
  function buyAsteroid(uint _tokenId) external payable {
    require(msg.value == getAsteroidPrice(_tokenId), "Incorrect amount of Ether sent");
    token.mint(_msgSender(), _tokenId);
    scans.recordScanOrder(_tokenId);
  }

  /**
   * @dev Withdraw Ether from the contract to owner address
   */
  function withdraw() external onlyOwner {
      uint balance = address(this).balance;
      _msgSender().transfer(balance);
  }
}
