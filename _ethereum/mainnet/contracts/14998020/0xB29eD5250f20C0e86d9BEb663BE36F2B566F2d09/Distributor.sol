pragma solidity ^0.8.8;

// SPDX-License-Identifier: MIT


import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./ERC721.sol";

/**
 * This contract acts as a vault for ERC721 contracts and allows people to either purchase for ETH
 * or lets external contract executor entity to transfer token via API
 */
contract Distributor is IERC721Receiver, Ownable {
  struct Distributable {
    uint256[] supply;
    uint256 price;
  }

  string constant NOT_TRACKED = "007001";
  string constant TRACKED = "007002";
  string constant SUPPLY_DEPLETED = "007003";
  string constant FUNDS_MISMATCH = "007004";
  string constant TRANSFER_FAILED = "007005";
  string constant SLIPPAGE_TOO_LOW = "007006";
  string constant SLIPPAGE_TOO_HIGH = "007007";
  string constant PRICE_SLIPPED = "007008";

  AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  mapping(ERC721 => Distributable) private _supply;
  ERC721[] private _tracked;
  address private _vault;

  constructor(address vault) Ownable() {
    _vault = vault;
  }

  /**
   * Add ERC721 contract to the watchlist
   */
  function addERC721(ERC721 erc721, uint256 price) public onlyOwner {
    require(!_isContractTracked(erc721), TRACKED);


    uint256[] memory _ids;
    _supply[erc721] = Distributable(_ids, price);
    _tracked.push(erc721);
  }

  /**
   * Update price
   */
  function updatePrice(ERC721 erc721, uint256 price) public onlyOwner {
    require(_isContractTracked(erc721), TRACKED);
    _supply[erc721].price = price;
  }

  /**
   * Retrieve available supply for the contract
   */
  function supply(ERC721 erc721) public view returns (uint256) {
    require(_isContractTracked(erc721), NOT_TRACKED);
    return _supply[erc721].supply.length;
  }

  /**
   * Requested estimated token price in wei
   *
   * @param erc721 address of the tracked ERC721 contract
   */
  function estimatePrice(ERC721 erc721) public view returns (int) {
    require(_isContractTracked(erc721), NOT_TRACKED);

    uint8 decimals = priceFeed.decimals();

    (
    /*uint80 roundID*/,
    int exchangeRate,
    /*uint startedAt*/,
    uint timeStamp,
    /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();
//    require(timeStamp > 0, 'No data');

    int tokenPrice = scalePrice(int(_supply[erc721].price), 0, 8);

    return scalePrice(tokenPrice * 100000000 / exchangeRate, 8, 18);
  }

  /**
   * Any external public entity can send ETH to the contract and retrieve and NFT token
   *
   * @param erc721 Address of the contract to interact with
   * @param to Address of the user to receive the token
   * @param slippage Tolerated rate slippage with with two decimals. E.g. 100 means 1% slippage.
   * Slippage cannot be higher than 5% (or 500)
   */
  function retrieve(ERC721 erc721, address to, uint8 slippage) public payable {
    require(_isContractTracked(erc721), NOT_TRACKED);

    require(msg.value > 0, FUNDS_MISMATCH);

    require(slippage < 500, SLIPPAGE_TOO_HIGH);
    require(slippage > 0, SLIPPAGE_TOO_LOW);

    uint256[] memory currentSupply = _supply[erc721].supply;
    require(currentSupply.length > 0, SUPPLY_DEPLETED);

    // Calculate price difference
    uint256 estimate = uint(estimatePrice(erc721));
    uint256 diff = (uint(msg.value - estimate) * 100 / msg.value) * 100;

    require(diff <= slippage, PRICE_SLIPPED);

    uint256 tokenId = currentSupply[currentSupply.length - 1];
    _supply[erc721].supply.pop();

    erc721.safeTransferFrom(address(this), to, tokenId);

    (bool sent,) = _vault.call{value : msg.value}("");
    require(sent, TRANSFER_FAILED);
  }

  /**
   * An entity w/ contract executor role can transfer token w/o sending payment
   *
   * Can be used to connect w/ Stripe or any other fiat payment gateway
   */
  function transfer(ERC721 erc721, address to) public onlyOwner {
    require(_isContractTracked(erc721), NOT_TRACKED);

    uint256[] memory currentSupply = _supply[erc721].supply;

    require(currentSupply.length > 0, SUPPLY_DEPLETED);

    uint256 tokenId = currentSupply[currentSupply.length - 1];
    _supply[erc721].supply.pop();

    erc721.transferFrom(address(this), to, tokenId);
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
    require(_isContractTracked(ERC721(operator)), NOT_TRACKED);

    _supply[ERC721(operator)].supply.push(tokenId);

    return bytes4(IERC721Receiver.onERC721Received.selector);
  }

  /**
   * Send the remaining supply to the vault and destroy the contract
   */
  function arrivederci() public onlyOwner {
    for (uint i = 0; i < _tracked.length; i++) {
      for (uint j = 0; j < _supply[_tracked[i]].supply.length; j++) {
        ERC721(_tracked[i]).transferFrom(address(this), _vault, _supply[_tracked[i]].supply[j]);
      }
    }

    selfdestruct(payable(_vault));
  }


  /**
   * Private
   */
  function _isContractTracked(ERC721 erc721) private view returns (bool) {
    return _supply[erc721].price > 0;
  }

  function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return _price * int256(10 ** uint256(_decimals - _priceDecimals));
    } else if (_priceDecimals > _decimals) {
      return _price / int256(10 ** uint256(_priceDecimals - _decimals));
    }

    return _price;
  }
}
