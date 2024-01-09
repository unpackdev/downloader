//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GBabyz is ERC721, Ownable {

  AggregatorV3Interface internal priceFeed;

  address payable public constant addr_ = 0x507a5c1a530879502054eD6E680DD9dbC8141A02;
  address public constant giveawayAddr_ = 0xb2B0E28B01db0454b7A0De76E5Edac5339985b2B;

  using Counters for Counters.Counter;
  Counters.Counter public _tokenIds;

  constructor() public ERC721("G-Babyz", "GBaby") {
    _setBaseURI("https://assets.gbabyz.com/meta");
    
    priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        
    for (uint256 i = 0; i < 52; i++) {
      _tokenIds.increment();
      _mint(giveawayAddr_, _tokenIds.current());
    }
  }

  uint256 public constant limit = 10000;
  uint256 public requested = 52;
  uint256 public constant gbabyPrice = 369 ether;

  function getLatestPrice() public view returns (uint) {
    (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return uint256(price / 1e8);
  }

  function mint()
    public
    payable
  {
    uint ethPrice = getLatestPrice();
    uint gbabyPriceEth = gbabyPrice.div(ethPrice);
    uint qty = msg.value.div(gbabyPriceEth);
    require( qty >= 1, "Not enough ETH");
    require( (requested + qty) <= limit, "Limit Reached, done minting" );
    require( msg.value >= gbabyPriceEth * qty, "Not enough ETH");
    (bool success,) = addr_.call{value: msg.value}("");
    require( success, "Could not complete, please try again");
    requested += qty;
    for (uint i = 1; i <= qty; i++ ) {
      _tokenIds.increment();
      _mint(msg.sender, _tokenIds.current());
    }
  }
}

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
