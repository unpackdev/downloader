// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Proxiable.sol"; 

/** 
* @dev Contract instance for Book Tokens
*/ 
contract BookilyBooks is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, Proxiable {

/** 
* @dev Name and Symbol not required, but provided to give consistency with ERC-721 in terms of display
* in tools like etherscan:
*/     
  string  private constant NAME = "Bookily Books";
  string  private constant SYMBOL = "BOOKS"; 
  address private constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
  uint    private constant SECONDS_PER_DAY = 24 * 60 * 60;
  address public token;
  address public treasury;
  
  /** 
  * @dev definition of token classes
  */     
  struct PublishedTitle {
    string  titleURI;     // 1 slot
    address mintingGate;  // 1 slot (160 + 64 + (8 * 2)) = 240
    uint64  maxSupply;
    uint8   specialDay;
    bool    award; 
    uint128 priceInWei;   // 1 slot (128 + 128) = 256
    uint128 priceInToken;
  }

  /** 
  * @dev map token classes to parameters:
  */    
  mapping (uint256 => PublishedTitle) publishedTitles; 

  /** 
  * @dev URI control constants. All URI data is stored permanently and 
  * immutably, but the display of information can be controlled by community
  * special days, sales volume, and when our titles win nobel prizes etc.:
  */    
  // Community based special days:
  string private constant SPECIAL_DAY = "/day";
  uint8  private constant NO_SPECIAL_DAY = 99;

  // Best sellers:
  string private constant SOLD_TEN = "/ten";
  string private constant SOLD_HUNDRED = "/hun";
  string private constant SOLD_THOUSAND = "/tho";
  string private constant SOLD_TEN_THOUSAND = "/tth";
  string private constant SOLD_HUNDRED_THOUSAND = "/hth";
  string private constant SOLD_MILLION = "/mil";
  string private constant SOLD_TEN_MILLION = "/tml";
  string private constant SOLD_HUNDRED_MILLION = "/hml";
  string private constant SOLD_BILLION = "/bil";

  // Award
  string private constant AWARD = "/awa";

  constructor() 
    ERC1155("base URI overriden") 
    Proxiable(0xfa3D2d059E9c0d348dB185B32581ded8E8243924) {
  }

  /** 
  * @dev modifier to ensure supply(s) is not exhausted:
  */ 
  modifier supplyNotExhausted(uint256 _tokenId, uint256 _quantity) {
    uint64 maxPrintRun = publishedTitles[_tokenId].maxSupply;
    // A maxSupply of 0 means no limit:
    if (maxPrintRun > 0) {
      require((totalSupply(_tokenId) + _quantity) <= publishedTitles[_tokenId].maxSupply, "Quantity exceeds max supply, cannot be minted. Sorry!");
    }
    _;
  }

  /** 
  * @dev events:
  */ 
  event TreasurySet(address treasury, uint256 effectiveDate);
  event TokenSet(address token, uint256 effectiveDate);
  event PriceInWeiSet(uint256 tokenId, uint128 priceInWei, uint256 effectiveDate);
  event PriceInTokenSet(uint256 tokenId, uint128 priceInToken, uint256 effectiveDate);
  event AwardSet(uint256 tokenId, bool award, uint256 effectiveDate);
  event SpecialDaySet(uint256 tokenId, uint8 specialDay, uint256 effectiveDate);
  event MaxSupplyReduced(uint256 tokenId, uint64 maxSupply, uint256 effectiveDate);
  event EthWithdrawal(uint256 indexed withdrawal, uint256 effectiveDate);
  event TokenWithdrawal(uint256 indexed withdrawal, address indexed tokenAddress, uint256 effectiveDate);
  event TitlePublished(uint256 tokenId, string titleURI, address mintingGate, uint64 maxSupply, uint8 specialDay, uint128 priceInWei, uint128 priceInToken);
  event BooksMinted(uint256 tokenId, uint256 quantity, uint256 ethPaid, uint256 tokenPaid, uint256 timestamp);

  /** 
  * @dev perform minting from ETH call:
  */ 
  function mintBook(uint256 _tokenId, uint256 _quantity, bool _proxied) external payable {
    
    // Check price paid:
    require(msg.value == _quantity * publishedTitles[_tokenId].priceInWei, "Incorrect payment amount");

    performMinting(msg.sender, _tokenId, _quantity, _proxied);
    
    emit BooksMinted(_tokenId, _quantity, msg.value, 0, block.timestamp); 
  }

  /** 
  * @dev perform minting from token call:
  */ 
  function mintBookUsingToken(address _caller, uint256 _tokenId, uint256 _quantity, uint256 _tokenPaid, bool _proxied) external payable {
    // Check this is the right token:
    require(msg.sender == token, "Invalid token");

    uint256 tokenPrice = publishedTitles[_tokenId].priceInToken;
    
    // Check token payment allowed:
    require(tokenPrice != 0, "Payment by token disabled");

    // Check price paid:
    require(_tokenPaid == _quantity * tokenPrice, "Incorrect payment amount");

    performMinting(_caller, _tokenId, _quantity, _proxied);

    emit BooksMinted(_tokenId, _quantity, 0, _tokenPaid, block.timestamp); 
  }

  /** 
  * @dev perform minting:
  */ 
  function performMinting(address _caller, uint256 _tokenId, uint256 _quantity, bool _proxied) internal supplyNotExhausted(_tokenId, _quantity) {
    
    address nominator;
    address delivery;
    
    // Allow proxied control for convenient delivery and checking of cold wallets for gated items
    // (for more details see https://docs.epsproxy.com/)
    if (_proxied) {
      bool isProxied;
      (nominator, delivery, isProxied) = getAddresses(_caller);
    }
    else {
      nominator = _caller;
      delivery = _caller;
    }

    // Check if a minting gate applies:
    address mintingGate = publishedTitles[_tokenId].mintingGate;
    if (mintingGate != ZERO_ADDRESS) {
      require(IERC721(mintingGate).balanceOf(nominator) >= 1, "Must hold an eligible token for this mint");
    }
 
    _mint(delivery, _tokenId, _quantity, "");
  }  

  /** 
  * @dev name and symbol for tools like etherscan:
  */ 
  function name() external pure returns (string memory) {
    return NAME;
  }

  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }

  /** 
  * @dev owner can publish new titles:
  */ 
  function publish(uint256 _tokenId, string calldata _titleURI, address _mintingGate, uint64 _maxSupply, uint8 _specialDay, uint128 _priceInWei, uint128 _priceInToken) external onlyOwner returns (bool) {
    publishedTitles[_tokenId].titleURI = _titleURI;
    publishedTitles[_tokenId].mintingGate = _mintingGate;
    publishedTitles[_tokenId].maxSupply = _maxSupply;
    publishedTitles[_tokenId].specialDay = _specialDay;
    publishedTitles[_tokenId].priceInWei = _priceInWei;
    publishedTitles[_tokenId].priceInToken = _priceInToken; 

    emit TitlePublished(_tokenId, _titleURI, _mintingGate, _maxSupply, _specialDay, _priceInWei, _priceInToken);
    return true;
  }

  /** 
  * @dev owner can update treasury address:
  */ 
  function setTreasury(address _treasury) external onlyOwner returns (bool) {
    treasury = _treasury;
    emit TreasurySet(_treasury, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can update token address:
  */ 
  function setToken(address _token) external onlyOwner returns (bool) {
    token = _token;
    emit TokenSet(_token, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can update price in wei:
  */ 
  function setPriceInWei(uint256 _tokenId, uint128 _priceInWei) external onlyOwner returns (bool) {
    publishedTitles[_tokenId].priceInWei = _priceInWei;
    emit PriceInWeiSet(_tokenId, _priceInWei, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can update price in token:
  */ 
  function setPriceInToken(uint256 _tokenId, uint128 _priceInToken) external onlyOwner returns (bool) {
    publishedTitles[_tokenId].priceInToken = _priceInToken;
    emit PriceInTokenSet(_tokenId, _priceInToken, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can update award status:
  */ 
  function setAward(uint256 _tokenId, bool _award) external onlyOwner returns (bool) {
    publishedTitles[_tokenId].award = _award;
    emit AwardSet(_tokenId, _award, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can update special day:
  */ 
  function setSpecialDay(uint256 _tokenId, uint8 _specialDay) external onlyOwner returns (bool) {
    publishedTitles[_tokenId].specialDay = _specialDay;
    emit SpecialDaySet(_tokenId, _specialDay, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can reduce supply:
  */ 
  function reduceSupply(uint256 _tokenId, uint64 _maxSupply) external onlyOwner returns (bool) {
    // A supply of 0 is unlimited, so under no circumstances can this be a valid update:
    require(_maxSupply != 0, "Cannot set to unlimited after initial publication");
    
    // A supply of 0 is unlimited, so always allow a reduction from unlimited:
    if (publishedTitles[_tokenId].maxSupply > 0) {    
      require(publishedTitles[_tokenId].maxSupply > _maxSupply, "Supply can only be decreased");
    }
    publishedTitles[_tokenId].maxSupply = _maxSupply;
    emit MaxSupplyReduced(_tokenId, _maxSupply, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can withdraw eth to treasury:
  */ 
  function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = treasury.call{value: _amount}("");
    require(success, "Transfer failed.");
    emit EthWithdrawal(_amount, block.timestamp);
    return true;
  }

  /** 
  * @dev owner can withdraw token to treasury:
  */ 
  function withdrawToken(uint256 _amount) external onlyOwner returns (bool) {
    bool success = IERC20(token).transfer(treasury, _amount);
    require(success, "Transfer failed.");
    emit TokenWithdrawal(_amount, token, block.timestamp);
    return true;
  }

  /** 
  * @dev all metadata is permanent at the point the title is published (there is no way
  * to update the URI information for any title), but the metadata used depends on sales
  * volume, awards and also community special days.
  */ 
  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    string memory constructedURI;
    // Start with the base URI:
    constructedURI   = publishedTitles[_tokenId].titleURI;
    bool  award      = publishedTitles[_tokenId].award;
    uint8 specialDay = publishedTitles[_tokenId].specialDay;

    // Look for special community day:
    if ((specialDay != NO_SPECIAL_DAY) && (specialDay == dayOfWeek())) {
      constructedURI = string(abi.encodePacked(constructedURI, SPECIAL_DAY));
    }
    else {

    // First derive the sales volume folder:
    uint256 sales = totalSupply(_tokenId);

      if      (sales < 10)          constructedURI = constructedURI;
      else if (sales < 100)         constructedURI = string(abi.encodePacked(constructedURI, SOLD_TEN)); 
      else if (sales < 1000)        constructedURI = string(abi.encodePacked(constructedURI, SOLD_HUNDRED));
      else if (sales < 10000)       constructedURI = string(abi.encodePacked(constructedURI, SOLD_THOUSAND));
      else if (sales < 100000)      constructedURI = string(abi.encodePacked(constructedURI, SOLD_TEN_THOUSAND));
      else if (sales < 1000000)     constructedURI = string(abi.encodePacked(constructedURI, SOLD_HUNDRED_THOUSAND));
      else if (sales < 10000000)    constructedURI = string(abi.encodePacked(constructedURI, SOLD_MILLION));
      else if (sales < 100000000)   constructedURI = string(abi.encodePacked(constructedURI, SOLD_TEN_MILLION));
      else if (sales < 1000000000)  constructedURI = string(abi.encodePacked(constructedURI, SOLD_HUNDRED_MILLION));
      else (                        constructedURI = string(abi.encodePacked(constructedURI, SOLD_BILLION))); 
      
      // Now add on any award (lol):
      if      (award)               constructedURI = string(abi.encodePacked(constructedURI, AWARD));
    }

    constructedURI = string(abi.encodePacked(constructedURI, "/metadata.json"));

    return constructedURI;
  }

  /** 
  * @dev derive the day of the week
  * 1 = Mon, 2 = Tue, 3 = Wed, 4 = Thu, 5 = Fri, 6 = Sat, 7 = Sun
  */ 
  function dayOfWeek() internal view returns (uint256 currentDay) {
      uint256 allDays = block.timestamp / SECONDS_PER_DAY;
      currentDay = (allDays + 3) % 7 + 1;
  }

  /** 
  * @dev get Title details
  */ 
  function getTitleDetails(uint256 _tokenId) external view returns 
  (PublishedTitle memory) {
    return(publishedTitles[_tokenId]);
  }

  /**
  * @dev revert any unidentified contract calls:
  */ 
  fallback() external payable {
    revert();
  }

  /**
  * @dev revert any unidentified payments:
  */ 
  receive() external payable {
    revert();
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
      internal
      override(ERC1155, ERC1155Supply) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}