pragma solidity ^0.8.2;

import "./AccessControl.sol";
import "./FeedRegistryInterface.sol";
import "./Denominations.sol";

import "./console.sol";
import "./StaticStorage.sol";
import "./IUriProvider.sol";

contract UriProvider is IUriProvider, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  event ConfigSet(uint256 rounds, uint256 skip, uint256 repeat, uint256 duration, uint256 magic);
  event StockMarketItemSet(uint256 index, string name, address oracle);

  uint256 private rounds;   // How many rounds of data to collect
  uint256 private skip;     // Step between chainlink price rounds
  uint256 private repeat;   // How many times each datapoint is repeated (min 1)
  uint256 private duration; // Must be between 10 and 99 seconds
  uint256 private magic;    // Delta x for datapoints is calculated as first price divided by this value

  uint256 constant DEFAULT_ROUNDS = 20;
  uint256 constant DEFAULT_SKIP = 10;
  uint256 constant DEFAULT_REPEAT = 4;
  uint256 constant DEFAULT_DURATION = 60;
  uint256 constant DEFAULT_MAGIC = 20;

  // Do not modify! These METADATA_X constants are automatically inserted by the embed.js script
  bytes constant METADATA_START = "data:application/json;charset=UTF-8,%7B%22description%22%3A%20%22A%20dynamically%20generated%20intergalactic%20token%20logo%20that%20cruises%20space%20based%20on%20its%20price%20fluctuations.%22%2C%20%22name%22%3A%20%22Intergalactic%20";
  bytes constant METADATA_MIDDLE = "%22%2C%20%22image%22%3A%20%22data:image/svg+xml;charset=UTF-8,";
  bytes constant METADATA_END = "%22%7D";

  // Do not modify! These SVG_X constants are automatically inserted by the embed.js script
  bytes constant SVG_INIT = "%3Csvg%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%20viewBox%3D'0%200%20300%20200'%3E";
  bytes constant SVG_PRE = "%3Cdefs%3E%3Crect%20id%3D'star'%20width%3D'2'%20height%3D'2'%2F%3E%3Cmask%20id%3D'mask'%20style%3D'mask-type%3Aalpha'%20maskUnits%3D'userSpaceOnUse'%20x%3D'0'%20y%3D'0'%20width%3D'300'%20height%3D'200'%3E%3Crect%20width%3D'300'%20height%3D'200'%2F%3E%3C%2Fmask%3E%3C%2Fdefs%3E%3Crect%20id%3D'background'%20width%3D'100%25'%20height%3D'100%25'%2F%3E%3Cg%20viewBox%3D'0%200%20300%20300'%20mask%3D'url(%23mask)'%3E%3Cuse%20href%3D'%23text'%3E%3CanimateMotion%20path%3D'm-40%20-32%20-400%200'%20begin%3D'0'%20dur%3D'7s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23text'%3E%3CanimateMotion%20path%3D'm-200%20140%20-400%200'%20begin%3D'0'%20dur%3D'7s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23text'%3E%3CanimateMotion%20path%3D'm548%20140%20-400%200'%20begin%3D'0'%20dur%3D'7s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3C%2Fg%3E%3Cg%20mask%3D'url(%23mask)'%3E%3Csvg%20x%3D'-30'%20y%3D'-15'%20height%3D'300'%20viewBox%3D'0%200%20280%20280'%3E%3Cg%20class%3D'price-container'%20transform-origin%3D'155%20100'%3E%3CanimateTransform%20attributeName%3D'transform'%20calcMode%3D'linear'%20attributeType%3D'XML'%20type%3D'rotate'%20repeatCount%3D'indefinite'%20"; 
  bytes constant SVG_POST = "%2F%3E%3Cg%3E%3Cuse%20href%3D'%23star'%3E%3CanimateMotion%20path%3D'm320%2020%20-240%200'%20begin%3D'0'%20dur%3D'1.3s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23star'%3E%3CanimateMotion%20path%3D'm380%2050%20-240%200'%20begin%3D'0.3s'%20dur%3D'1.3s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23star'%3E%3CanimateMotion%20path%3D'm240%2080%20-240%200'%20begin%3D'0.15s'%20dur%3D'13s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23star'%3E%3CanimateMotion%20path%3D'm280%20130%20-240%200'%20begin%3D'0.3s'%20dur%3D'1.3s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23star'%3E%3CanimateMotion%20path%3D'm380%20160%20-240%200'%20begin%3D'0.15s'%20dur%3D'1.3s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3Cuse%20href%3D'%23star'%3E%3CanimateMotion%20path%3D'm200%20190%20-240%200'%20begin%3D'0'%20dur%3D'1.3s'%20repeatCount%3D'indefinite'%2F%3E%3C%2Fuse%3E%3C%2Fg%3E%3Csvg%20id%3D'rainbow'%20y%3D'85'%3E%3Cdefs%3E%3ClinearGradient%20id%3D'RainbowGradient'%20gradientTransform%3D'rotate(90)'%3E%3Cstop%20stop-color%3D'%23FF00FF'%20offset%3D'0%25'%2F%3E%3Cstop%20stop-color%3D'%23FF00FF'%20offset%3D'16.66%25'%2F%3E%3Cstop%20stop-color%3D'%236960EC'%20offset%3D'16.67%25'%2F%3E%3Cstop%20stop-color%3D'%236960EC'%20offset%3D'33.33%25'%2F%3E%3Cstop%20stop-color%3D'%2300FFFF'%20offset%3D'33.34%25'%2F%3E%3Cstop%20stop-color%3D'%2300FFFF'%20offset%3D'49.99%25'%2F%3E%3Cstop%20stop-color%3D'%230DFF27'%20offset%3D'50.00%25'%2F%3E%3Cstop%20stop-color%3D'%230DFF27'%20offset%3D'66.66%25'%2F%3E%3Cstop%20stop-color%3D'%23FFF20D'%20offset%3D'66.67%25'%2F%3E%3Cstop%20stop-color%3D'%23FFF20D'%20offset%3D'83.33%25'%2F%3E%3Cstop%20stop-color%3D'%23FF5F1F'%20offset%3D'83.34%25'%2F%3E%3Cstop%20stop-color%3D'%23FF5F1F'%20offset%3D'100%25'%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%3Cstyle%3E.rainbow-piece0%7Banimation%3Arainbow-updown%20.4s%20linear%20infinite%7D.rainbow-piece1%7Banimation%3Arainbow-updown%20.4s%20linear%20-.2s%20infinite%7D%40keyframes%20rainbow-updown%7B0%25%7Btransform%3Atranslate(0%2C0)%7D49.99%25%7Btransform%3Atranslate(0%2C0)%7D50%25%7Btransform%3Atranslate(0%2C2px)%7D100%25%7Btransform%3Atranslate(0%2C2px)%7D%7D%3C%2Fstyle%3E%3Cg%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece0'%20y%3D'0'%20x%3D'-60'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece1'%20y%3D'0'%20x%3D'-30'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece0'%20y%3D'0'%20x%3D'0'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece1'%20y%3D'0'%20x%3D'30'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece0'%20y%3D'0'%20x%3D'60'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece1'%20y%3D'0'%20x%3D'90'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3Crect%20class%3D'rainbow-piece%20rainbow-piece0'%20y%3D'0'%20x%3D'120'%20width%3D'30'%20height%3D'40'%20fill%3D'url(%23RainbowGradient)'%2F%3E%3C%2Fg%3E%3C%2Fsvg%3E%3Cuse%20href%3D'%23logo'%2F%3E%3C%2Fg%3E%3C%2Fsvg%3E%3C%2Fg%3E%3C%2Fsvg%3E";
  
  // But these are not, so yeah, modify them here if you change them in the SVG
  string constant STOCK_MARKET_BEGIN = "%3Cdefs%3E%3Ctext%20id%3D'text'%20x%3D'60'%20y%3D'50'%3E";
  string constant STOCK_MARKET_END = "%3C%2Ftext%3E%3C%2Fdefs%3E";
  string constant STOCK_MARKET_ITEM_OPEN_START_TAG = "%3Ctspan%20id%3D'";
  string constant STOCK_MARKET_ITEM_CLOSE_START_TAG = "'%3E%20";
  string constant STOCK_MARKET_ITEM_UP = "%20%E2%96%B2%20%2B";
  string constant STOCK_MARKET_ITEM_DOWN = "%20%E2%96%BC%20-";
  string constant STOCK_MARKET_ITEM_END_TAG = "%25%20%3C%2Ftspan%3E%20-%20";
  string constant ANIMATION_ITEM_START = "values%3D'";
  string constant ANIMATION_ITEM_MIDDLE = "'%20dur%3D'";
  string constant ANIMATION_ITEM_END = "s'";

  // Data for writing stock market marquee
  uint256 constant STOCK_MARKET_MAX_ITEMS = 10;
  string[STOCK_MARKET_MAX_ITEMS] private stockMarketNames;
  address[STOCK_MARKET_MAX_ITEMS] private stockMarketOracles;

  mapping(uint256 => address) private logos;

  constructor(string[] memory _stockMarketNames, address[] memory _stockMarketOracles) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    
    require(_stockMarketNames.length == _stockMarketOracles.length, "Length mismatch");
    require(_stockMarketNames.length <= STOCK_MARKET_MAX_ITEMS, "Too long");

    for (uint256 i = 0; i < _stockMarketNames.length; i++) {
      stockMarketNames[i] = _stockMarketNames[i];
      stockMarketOracles[i] = _stockMarketOracles[i];
      emit StockMarketItemSet(i, _stockMarketNames[i], _stockMarketOracles[i]);
    }

    rounds = DEFAULT_ROUNDS;
    skip = DEFAULT_SKIP;
    magic = DEFAULT_MAGIC;
    repeat = DEFAULT_REPEAT;
    duration = DEFAULT_DURATION;

    emit ConfigSet(DEFAULT_ROUNDS, DEFAULT_SKIP, DEFAULT_MAGIC, DEFAULT_REPEAT, DEFAULT_DURATION);
  }

  function getConfig() external view returns (uint256, uint256, uint256, uint256, uint256) {
    return (rounds, skip, magic, repeat, duration);
  }

  function setConfig(uint256 _rounds, uint256 _skip, uint256 _magic, uint256 _repeat, uint256 _duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
    rounds = _rounds;
    skip = _skip;
    magic = _magic;
    repeat = _repeat;
    duration = _duration;
    emit ConfigSet(_rounds, _skip, _repeat, _duration, _magic);
  }

  function setStockMarketItem(uint256 index, string memory name, address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
    stockMarketNames[index] = name;
    stockMarketOracles[index] = oracle;
    emit StockMarketItemSet(index, name, oracle);
  }

  function getLogo(uint256 tokenId) internal view returns (string memory) {
    return string(StaticStorage.readData(logos[tokenId]));
  }

  function setLogo(uint256 tokenId, address logo) external onlyRole(MINTER_ROLE) {
    logos[tokenId] = logo;
  }

  function writeLogo(uint256 tokenId, string memory data) external onlyRole(MINTER_ROLE) returns (address logo) {
    logo = StaticStorage.createData(bytes(data));
    logos[tokenId] = logo;
    return logo;
  }

  function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
    int256[] memory prices = getPrices(tokenId);
    int256[] memory slopes = getSlopes(prices);
    string memory svgLogo = getLogo(tokenId);
    string memory name = getName(tokenId);
    string memory stock = buildStockMarket();

    return string(abi.encodePacked(
      METADATA_START,
      name,
      METADATA_MIDDLE,
      buildSVG(svgLogo, slopes, stock),
      METADATA_END
    ));
  }

  function getName(uint256 tokenId) internal view returns(string memory) {
    AggregatorV3Interface aggregatorProxy = AggregatorV3Interface(address(uint160(tokenId)));
    console.log("Aggregator proxy %s", address(aggregatorProxy));
    return aggregatorProxy.description();
  }

  function getPrices(uint256 tokenId) internal view returns(int256[] memory) {
    AggregatorInterface aggregatorProxy = AggregatorInterface(address(uint160(tokenId)));
    console.log("Aggregator proxy %s", address(aggregatorProxy));
  
    int256[] memory prices = new int256[](rounds);
    uint256 roundId = aggregatorProxy.latestRound();
    console.log("Latest round is %s", roundId);

    for (uint256 i = rounds; i > 0; i--) {
      int256 price = aggregatorProxy.getAnswer(roundId);
      console.log("Got price %s for round %s", uint256(price), roundId);
      if (price == 0) price = prices[i];
      prices[i-1] = price;
      roundId -= skip;
    }
    return prices;
  }

  function getStockMarketVariation(address oracle) private view returns(int256) {
    console.log("Fetching variation from %s", oracle);

    AggregatorInterface aggregatorProxy = AggregatorInterface(oracle);
    uint256 roundId = aggregatorProxy.latestRound();
    int256 currentPrice = aggregatorProxy.getAnswer(roundId);
    
    // We go back to the first price we collect for this animation,
    // and try 10 different rounds if we get a missing response
    roundId -= skip * rounds;
    for (uint256 i = 0; i < 10; i++) {
      int256 oldPrice = aggregatorProxy.getAnswer(roundId);
      if (oldPrice != 0) {
        int256 variation = ((currentPrice - oldPrice) * 10000) / oldPrice;
        console.log("Got price=%s oldPrice=%s variation=%s", uint256(currentPrice), uint256(oldPrice), uint256(variation));
        return variation;
      }
    }

    // Bail with zero if we don't get any response
    console.log("Got no variation from oracle");
    return 0;
  }

  function getSlopes(int256[] memory prices) internal view returns(int256[] memory) {
    int256 period = prices[0] / int256(magic);
    int256[] memory slopes = new int256[](prices.length + 1);
    slopes[0] = 0;
    slopes[prices.length] = 0;
    for (uint256 i = 1; i < prices.length - 1; i++) {
      int256 y = prices[i] - prices[i-1];
      int256 s = arctan(period, (y < 0 ? -y : y));
      slopes[i] = y < 0 ? -s : s;
    }
    return slopes;
  }

  function arctan(int256 x, int256 y) private view returns (int256) {
    // We approx arctan using different formulas depending if x > y
    if (y == 0) {
      return 0;
    } else if (x > y) {
      // From https://www.embedded.com/performing-efficient-arctangent-approximation/
      console.log("Using f1 for x=%s y=%s", uint256(x), uint256(y));
      return (57 * 100000 * y * x) / (100000 * x * x + 28125 * y * y);
    } else {
      // From https://math.stackexchange.com/questions/982838/asymptotic-approximation-of-the-arctangent
      // We approximate arctan by pi/2 - 1/(y/x), which returns a value in rad, and convert to deg
      console.log("Using f2 for x=%s y=%s", uint256(x), uint256(y));
      return (57 * (22 * y - 14 * x)) / (14 * y);
    }
  }

  function buildSVG(string memory svgLogo, int256[] memory slopes, string memory variations) internal view returns(string memory) {
    return string(abi.encodePacked(
      SVG_INIT, 
      svgLogo,
      variations,
      SVG_PRE, 
      buildAnimationAttrs(slopes),
      SVG_POST
    ));
  }

  function buildAnimationAttrs(int256[] memory slopes) private view returns (string memory) {
    uint256 reps = repeat;
    uint256 dur = duration;
    
    // Build animation values
    uint256 valuesLen = 4 * slopes.length * reps; 
    bytes memory valuesAttr = new bytes(valuesLen);
    uint ptr = 0;
    
    for (uint256 i = 0; i < slopes.length; i++) {
      int256 slope = slopes[i];
      uint8 abs = slope < 0 ? uint8(uint256(-slope)) : uint8(uint256(slope));
      for (uint256 j = 0; j < reps; j++) {
        valuesAttr[ptr++] = bytes1(slope < 0 ? 45 : 32);
        valuesAttr[ptr++] = bytes1((abs % 100) / 10 + 48);
        valuesAttr[ptr++] = bytes1(uint8(abs % 10) + 48);
        valuesAttr[ptr++] = ";";
      }
    }

    // Build duration
    bytes memory durAttr = new bytes(2);
    durAttr[0] = bytes1(uint8(dur % 100) / 10 + 48);
    durAttr[1] = bytes1(uint8(dur % 10) + 48);
    
    // Concatenate all
    return string(abi.encodePacked(
      ANIMATION_ITEM_START, 
      valuesAttr, 
      ANIMATION_ITEM_MIDDLE, 
      durAttr, 
      ANIMATION_ITEM_END
    ));
  }

  function buildStockMarket() internal view returns (string memory) {
    return string(abi.encodePacked(
      STOCK_MARKET_BEGIN,
      buildStockMarketItem(0),
      buildStockMarketItem(1),
      buildStockMarketItem(2),
      buildStockMarketItem(3),
      buildStockMarketItem(4),
      buildStockMarketItem(5),
      buildStockMarketItem(6),
      buildStockMarketItem(7),
      buildStockMarketItem(8),
      buildStockMarketItem(9),
      STOCK_MARKET_END
    ));
  }

  function buildStockMarketItem(uint256 index) private view returns (string memory) {
    address oracle = stockMarketOracles[index];
    if (oracle == address(0)) return "";

    int256 variation = getStockMarketVariation(oracle);
    
    return string(abi.encodePacked(
      STOCK_MARKET_ITEM_OPEN_START_TAG,
      variation > 0 ? "up" : (variation < 0 ? "down" : ""),
      STOCK_MARKET_ITEM_CLOSE_START_TAG,
      stockMarketNames[index],
      variation > 0 ? STOCK_MARKET_ITEM_UP : (variation < 0 ? STOCK_MARKET_ITEM_DOWN : " "),
      toPercentage(variation),
      STOCK_MARKET_ITEM_END_TAG
    ));
  }

  function toPercentage(int256 value) private pure returns (string memory) {
    if (value == 0) return "0.00";
    
    uint256 absvalue = value > 0 ? uint256(value) : uint256(-value);
    
    uint256 temp = absvalue;
    uint256 digits = 1;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    if (digits < 4) digits = 4;
    
    bytes memory buffer = new bytes(digits);

    while (digits > 0) {
      digits -= 1;
      if (digits == buffer.length - 3) {
        buffer[digits] = ".";
        continue;
      }
      buffer[digits] = bytes1(uint8(48 + uint256(absvalue % 10)));
      absvalue /= 10;
    }
    return string(buffer);
  }
}