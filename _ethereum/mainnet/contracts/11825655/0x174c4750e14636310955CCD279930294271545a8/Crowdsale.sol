// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

import "./STOToken.sol";

contract Crowdsale is Initializable, OwnableUpgradeSafe, PausableUpgradeSafe {
  using SafeMath for uint256;

  uint256 private _decimals = 18; // ETH decimals

  AggregatorV3Interface private _ethUsdFeed;
  AggregatorV3Interface private _eurUsdFeed;
  bool internal _feedsLoaded = false;

  struct TokenInfo {
      address tokenAddress;
      uint256 price; // EUR
  }

  mapping(string => TokenInfo) private _availableTokens;

  event EnabledToken(string tokenName, address indexed tokenAddress, uint32 price);
  event Contribution(string tokenName, address indexed holderAddress, uint256 eth, uint256 tokens);
  event Destroyed();

  function initialize() public {
    __Crowdsale_init();
  }

  function __Crowdsale_init() internal initializer {
    __Context_init_unchained();
    __Ownable_init();
  }

  function updateFeeds(address addressEurUsd, address addressEthUsd) public onlyOwner {
    _eurUsdFeed = AggregatorV3Interface(addressEurUsd);
    _ethUsdFeed = AggregatorV3Interface(addressEthUsd);
    _feedsLoaded = true;
  }

  function pause() public onlyOwner{
    _pause();
  }

  function unpause() public onlyOwner{
    _unpause();
  }

  function contribution(string memory tokenName) public payable whenNotPaused returns (uint256) {
    uint256 tokens = getTokensByContribution(msg.value, tokenName);
    TokenInfo memory tokenInfo = _availableTokens[tokenName];
    STOToken token = STOToken(tokenInfo.tokenAddress);
    token.mint(_msgSender(), tokens);
    require(payable(owner()).send(msg.value), "Crowdsale: Funds NOT transfered");
    emit Contribution(tokenName, _msgSender(), msg.value, tokens);
    return tokens;
  }

  function getRates() public view returns(uint256 ethRate, uint256 eurRate) {
    (,int256 ethAnswer,,,) = _ethUsdFeed.latestRoundData();
    (,int256 eurAnswer,,,) = _eurUsdFeed.latestRoundData();

    uint8 ethDecimals = _ethUsdFeed.decimals();
    uint8 eurDecimals = _eurUsdFeed.decimals();

    uint256 divEth = uint256(10**uint256(_decimals - ethDecimals));
    uint256 divEur = uint256(10**uint256(_decimals - eurDecimals));

    // Rate with 18 decimals
    ethRate = uint256(ethAnswer).mul(divEth);
    eurRate = uint256(eurAnswer).mul(divEur);
  }

  function getTokensByContribution(uint amount, string memory tokenName) public view returns (uint256) {
    require(_feedsLoaded, "Crowdsale: feeds NOT linked");
    require(_availableTokens[tokenName].tokenAddress != address(0), "Crowdsale: project NOT exists");
    uint256 priceTokenEur = _availableTokens[tokenName].price;
    (uint256 ethRate, uint256 eurRate) = getRates();
    uint256 safeDecimals = uint256(10**8);
    uint256 numTokensProject = uint256(amount.mul(safeDecimals)).div(uint256(priceTokenEur).mul(eurRate.mul(safeDecimals)).div(ethRate));
    return numTokensProject;
  }

  function isEnabledToken(string memory tokenName) public view returns (bool) {
    return _availableTokens[tokenName].tokenAddress != address(0);
  }

  function getTokenAddress(string memory tokenName) public view returns (address) {
    require(_availableTokens[tokenName].tokenAddress != address(0), "Crowdsale: project NOT exists");
    return _availableTokens[tokenName].tokenAddress;
  }

  function enableToken(string memory tokenName, address tokenAddress, uint32 price) public onlyOwner {
    require(tokenAddress != address(0), "Crowdsale: token address is the zero address");
    bool canMint = STOToken(tokenAddress).hasRole(keccak256("MINTER_ROLE"), address(this));
    require(canMint, "Crowdsale: crowdsale address NOT has MINTER_ROLE on token");
    _availableTokens[tokenName] = TokenInfo({
        tokenAddress: tokenAddress,
        price: price
    });
    emit EnabledToken(tokenName, tokenAddress, price);
  }

  function destroy() public onlyOwner {
    emit Destroyed();
    selfdestruct(payable(owner()));
  }
}
