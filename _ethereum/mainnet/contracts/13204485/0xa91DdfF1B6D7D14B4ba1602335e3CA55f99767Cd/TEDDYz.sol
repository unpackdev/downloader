// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract TEDDYz is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  // Supply and price
  uint public constant MAX_SUPPLY = 10000;
  uint256 public mintPrice = 0.04 ether;
  uint public constant maxPurchaseSize = 30;

  // Basic variables
  bool public paused = false;
  bool public open = false;
  address[] private _owners;
  string private _baseTokenURI;

  // -------- Modifiers -------- 
  modifier isOpen {
    require(totalSupply() < MAX_SUPPLY, "Sale has ended");
    require(open, "Sale not open yet");
    _;
  }

  modifier notPaused {
    require(!paused, "Minting has beend paused");
    _;
  }

  modifier ownersOnly {
    bool isOwner = false;
    for (uint i=0; i<_owners.length && !isOwner; i++) {
      if(msg.sender == _owners[i])
        isOwner = true;
    }
    if(msg.sender == owner())
      isOwner = true;
    require(isOwner, "Function only allowed for owners");
    _;
  }


  // -------- Public methods -------- 

  /**
   * @dev Constructor
   */
  constructor(string memory name, string memory symbol, string memory baseURI, address[] memory ownersList) ERC721(name, symbol)  {
    setBaseURI(baseURI);
    setOwners(ownersList);
  }

  /**
   * @dev Mint new quantity amount of nfts
   */
  function mint(uint quantity) public payable isOpen notPaused {
    require(quantity > 0, "You can't mint 0");
    require(quantity <= maxPurchaseSize, "Exceeds max per transaction");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough token left");

    uint256 price = mintPrice.mul(quantity);
    require(msg.value >= price, "Value below order price");
    for(uint i = 0; i < quantity; i++){
        _safeMint(msg.sender, totalSupply().add(1));
    }

    uint256 remaining = msg.value.sub(price);
    if (remaining > 0) {
      (bool success, ) = msg.sender.call{value: remaining}("");
      require(success);
    }
  }

  /**
   * @dev Returns all the token IDs owned by address who
   */
  function tokensOfAddress(address who) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(who);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      tokensId[i] = tokenOfOwnerByIndex(who, i);
    }
    return tokensId;
  }

  // -------- owners only methods -------- 

  /**
   * @dev Mint new quantity amount of nfts
   */
  function withdraw() public ownersOnly payable  {
    uint256 balance = address(this).balance;
    for (uint i=0; i<_owners.length; i++) {
      (bool success, ) = payable(_owners[i]).call{
        value: balance.div(_owners.length)
      }("");
      require(success);
    }
  }

  /**
   * @dev Mint new quantity amount of nfts
   */
  function emergyWithdraw() public onlyOwner payable  {
    uint256 balance = address(this).balance;
    (bool success, ) = payable(owner()).call{
      value: balance
    }("");
    require(success);
  }

  /**
   * @dev Mint new quantity amount of nfts for specific address
   * Bypass pause modifier
   */
  function ownerMint(uint quantity) public ownersOnly {
    require(quantity > 0, "You can't mint 0");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough token left");
    for(uint i = 0; i < quantity; i++){
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Set minting price
   */
  function setMintPrice(uint256 price) public ownersOnly {
    mintPrice = price;
  }

  /**
   * @dev Pause or unpause the minting
   */
  function setPause(bool value) public ownersOnly {
    paused = value;
  }

  /**
   * @dev Open the minting (initially closed)
   */
  function setOpen(bool value) public ownersOnly {
    open = value;
  }

  /**
   * @dev Set base token URI
   */
  function setBaseURI(string memory baseURI) public ownersOnly {
    _baseTokenURI = baseURI;
  }

  /**
   * @dev Set owners
   */
  function setOwners(address[] memory ownersList) public onlyOwner {
    _owners = ownersList;
  }

  // -------- Override methods -------- 

  /**
   * @dev override of _baseURI()
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
}

