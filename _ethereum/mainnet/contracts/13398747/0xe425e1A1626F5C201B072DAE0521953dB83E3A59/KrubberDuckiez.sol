// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title Krubber Duckiez ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract KrubberDuckiez is ERC721Enumerable, Ownable, Pausable {
  using SafeMath for uint256;
  using Address for address payable;

  uint256 public constant KRUB_PREMINT = 50;
  uint256 public constant KRUB_GIFT = 100;
  uint256 public constant KRUB_MAX = 11111;
  uint256 public constant KRUB_MAX_PRESALE = 6000;
  uint256 public constant KRUB_PRICE = 0.08 ether;
  uint256 public constant KRUB_PER_WALLET = 25;
  uint256 public constant KRUB_PER_WALLET_PRESALE = 10;

  uint256 private _totalWhitelisted;

  uint256 public totalGifted;

  mapping(address => bool) private whitelist;

  mapping(address => uint256) public addressToMinted;

  string private _baseTokenURI;
  string private _contractURI;

  bool public presaleLive;
  bool public saleLive;

  address private _devAddress = 0xbB61A5398EeF5707fa662F42B7fC1Ca32e76e747;

  constructor(string memory newBaseTokenURI, string memory newContractURI)
    ERC721("Krubber Duckiez", "KRUB")
  {
    _baseTokenURI = newBaseTokenURI;
    _contractURI = newContractURI;

    _preMint(KRUB_PREMINT);
  }

  /**
   * @dev Mints number of tokens specified to wallet during presale.
   * @param quantity uint256 Number of tokens to be minted
   */
  function presaleBuy(uint256 quantity) external payable whenNotPaused {
    require(presaleLive, "KrubberDuckiez: Presale not currently live");
    require(!saleLive, "KrubberDuckiez: Sale is no longer in the presale stage");
    require(whitelist[msg.sender], "KrubberDuckiez: Caller is not eligible for presale");
    require(totalSupply() <= (KRUB_MAX_PRESALE - quantity), "KrubberDuckiez: Quantity exceeds remaining tokens");
    require(quantity <= (KRUB_PER_WALLET_PRESALE - addressToMinted[msg.sender]), "KrubberDuckiez: Wallet cannot mint any new tokens");
    require(quantity != 0, "KrubberDuckiez: Cannot buy zero tokens");
    require(msg.value >= (quantity * KRUB_PRICE), "KrubberDuckiez: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      addressToMinted[msg.sender]++;
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable whenNotPaused {
    require(!presaleLive, "KrubberDuckiez: Sale is currently in the presale stage");
    require(saleLive, "KrubberDuckiez: Sale is not currently live");
    require(totalSupply() <= (KRUB_MAX - quantity), "KrubberDuckiez: Quantity exceeds remaining tokens");
    require(quantity <= (KRUB_PER_WALLET - addressToMinted[msg.sender]), "KrubberDuckiez: Wallet cannot mint any new tokens");
    require(quantity != 0, "KrubberDuckiez: Cannot buy zero tokens");
    require(msg.value >= (quantity * KRUB_PRICE), "KrubberDuckiez: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      addressToMinted[msg.sender]++;
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Gifts tokens to addresses.
   * @param wallets address[] Ethereum wallets to mint tokens to
   */
  function gift(address[] calldata wallets) external onlyOwner {
    require(!presaleLive && !saleLive, "KrubberDuckiez: Cannot gift during sale or presale");
    require(totalSupply() <= (KRUB_MAX - wallets.length), "KrubberDuckiez: Quantity exceeds remaining tokens");
    require(totalGifted + wallets.length <= KRUB_GIFT, "KrubberDuckiez: Quantity exceeds max number of gifted tokens");

    for (uint256 i=0; i<wallets.length; i++) {
      totalGifted++;
      _safeMint(wallets[i], totalSupply().add(1));
    }
  }

  /**
   * @dev Checks if wallet address is whitelisted.
   * @param wallet address Ethereum wallet to be checked
   * @return bool Presale eligibility of address
   */
  function isWhitelisted(address wallet) external view returns (bool) {
    return whitelist[wallet];
  }

  /**
   * @dev Add addresses to whitelist.
   * @param wallets address[] Ethereum wallets to authorise
   */
  function addToWhitelist(address[] calldata wallets) external onlyOwner {
    for(uint256 i = 0; i < wallets.length; i++) {
      address wallet = wallets[i];
      require(wallet != address(0), "KrubberDuckiez: Cannot add zero address");
      require(!whitelist[wallet], "KrubberDuckiez: Duplicate address");

      whitelist[wallet] = true;
      _totalWhitelisted++;
    }   
  }

  /**
   * @dev Remove addresses from whitelist.
   * @param wallets address[] Ethereum wallets to deauthorise
   */
  function removeFromWhitelist(address[] calldata wallets) external onlyOwner {
    for(uint256 i = 0; i < wallets.length; i++) {
      address wallet = wallets[i];
      require(wallet != address(0), "KrubberDuckiez: Cannot add zero address");
          
      whitelist[wallet] = false;
      _totalWhitelisted--;
    }
  }

  /**
   * @dev Returns total number of whitelisted addresses.
   * @return uint256 Number of addresses in whitelist
   */
  function getTotalWhitelisted() external view onlyOwner returns (uint256) {
    return _totalWhitelisted;
  }
  
  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "KrubberDuckiez: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
  }

  /**
   * @dev Returns contract URI.
   * @return string Contract URI
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Toggles status of token presale. Only callable by owner.
   */
  function togglePresale() external onlyOwner {
    presaleLive = !presaleLive;
  }

  /**
   * @dev Toggles status of token sale. Only callable by owner.
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() public onlyOwner {
    payable(_devAddress).sendValue(address(this).balance * 2 / 100);  // 2%
    payable(msg.sender).sendValue(address(this).balance);
  }

  /**
   * @dev Pre mint n tokens to owner address.
   * @param n uint256 Number of tokens to be minted
   */
  function _preMint(uint256 n) private {
    for (uint256 i=0; i<n; i++) {
      _safeMint(owner(), totalSupply().add(1));
    }
  }
}
