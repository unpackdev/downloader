// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AggregatorV3Interface.sol";

contract BaseChannelThree is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;
  AggregatorV3Interface internal priceFeed;

  string private _updatableBaseURI;
  uint256 private _mintFeeUsd;

  constructor(address _initPriceFeed, string memory _initUpdatableBaseURI, uint256 _initMintFeeUsd) ERC721('3ch', '3ch') {
    priceFeed = AggregatorV3Interface(_initPriceFeed);
    _updatableBaseURI = _initUpdatableBaseURI;
    _mintFeeUsd = _initMintFeeUsd;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner() {
    _updatableBaseURI = baseURI;
  }

  function setMintFeeUsd(uint256 usd) external onlyOwner() {
    _mintFeeUsd = usd;
  }

  function mintFeeUsd() public view returns (uint256) {
    return _mintFeeUsd;
  }

  function getLatestPrice() public virtual view returns (int) {
    (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
    return price;
  }

  function usdToWei(uint usd) public view returns (uint) {
    uint denominator = uint(getLatestPrice()); 
    uint256 ethInUsdAmount = usd * 1000000000000000000000 / denominator * 100000; 
    return ethInUsdAmount;
  }

  function withdraw() external onlyOwner() {
    payable(owner()).transfer(address(this).balance);
  }

  function _baseURI() internal view override returns (string memory) {
    return _updatableBaseURI;
  }

  function safeMint() public payable returns (uint256) {
    require(msg.value == usdToWei(mintFeeUsd()), 'Invalid fee');

    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(msg.sender, tokenId);
    return tokenId;
  }


  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}

contract TestChannelThree is BaseChannelThree {
  constructor() BaseChannelThree(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 'https://3ch.app/api/tokens/', 1) {
  }

  function getLatestPrice() public pure override returns (int) {
    // https://docs.chain.link/docs/get-the-latest-price
    return 331770500973;
  }
}

contract RinkebyChannelThree is BaseChannelThree {
  constructor() BaseChannelThree(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e, 'https://rinkeby.3ch.app/api/tokens/', 1) {
  }
}

contract ChannelThree is BaseChannelThree {
  constructor() BaseChannelThree(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 'https://3ch.app/api/tokens/', 1) {
  }
}