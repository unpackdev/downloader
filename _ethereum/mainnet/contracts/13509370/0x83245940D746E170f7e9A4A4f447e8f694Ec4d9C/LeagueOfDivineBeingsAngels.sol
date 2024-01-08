//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";



// ERC-721
string constant TOKEN_NAME = "LODB Angels Collection";
string constant TOKEN_SYMBOL = "LODBA";

// Token Metadata
string constant BASE_URI = "ipfs://QmUV8D1YUV6sEk6gGi8gso3dEDevWsJidsK5Ubz1P87k8q/";

// Minting Payment
uint constant SALE_PRICE = 0.0333 ether;

// Token Supply
uint constant MAX_SUPPLY = 10000;
uint constant RESERVED_SUPPLY = 100;
uint constant FOR_SALE_SUPPLY = MAX_SUPPLY - RESERVED_SUPPLY;

// Presale
address constant DEVILS_CONTRACT_ADDRESS = 0xF642D8A98845a25844D3911Fa1da1D70587c0Acc;

// Sale Price
uint constant PUBLIC_SALE_PRICE = 0.0333 ether;

// Sale Schedule
uint constant PUBLIC_SALE_OPEN_TIME = 1636171260; // Saturday November 06, 2021 00:01:00 (am) in time zone America/New York (EDT)
                                      
// OpenSea
address constant OPENSEA_PROXY_REGISTRY_ADDRESS = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; 

struct LeagueOfDivineBeingsAngelsParams {
  address owner;
  address payable treasury;
}

contract LeagueOfDivineBeingsAngels is
  Ownable,
  ERC721Enumerable
{
  // # Token Supply
  uint private _totalMintedCount = 0;
  uint private _reservedMintedCount = 0;
  uint private _saleMintedCount = 0;

  // # Minting Payment
  address payable private _treasury;
  event SetTreasury(address prevTreasury, address newTreasury);

  // # Sale Schedule
  event SalePaused();
  event SaleUnpaused();

  // # Sale Pausable
  bool private _salePaused = false;

  // # Presale
  mapping(uint => bool) public claimedDevils;



  constructor(LeagueOfDivineBeingsAngelsParams memory p)
    ERC721(TOKEN_NAME, TOKEN_SYMBOL)
  {
    setTreasury(p.treasury);
    transferOwnership(p.owner);
  }



  // # Token Metadata

  function _baseURI() override internal pure returns (string memory) {
    return BASE_URI;
  }



  // # Minting Supply

  function _requireNotSoldOut() private view {
    require(
      _saleMintedCount <= FOR_SALE_SUPPLY,
      "SOLD OUT"
    );
  }

  function _requireValidQuantity(uint quantity) private pure {
    require(
      quantity > 0,
      "quantity must be greater than 0"
    );
    require(
      quantity <= FOR_SALE_SUPPLY,
      "quantity must be less than FOR_SALE_SUPPLY"
    );
  }

  function _requireEnoughSupplyRemaining(uint mintQuantity) private view {
    require(
      _saleMintedCount + mintQuantity <= FOR_SALE_SUPPLY,
      string(abi.encode("Not enough supply remaining to mint quantity of ", mintQuantity))
    );
  }



  // # Sale Pausable

  function salePaused() external view returns (bool) {
    return _salePaused;
  }

  function _requireSaleNotPaused() private view {
    require(!_salePaused, "Sale is paused");
  }

  function _requireSalePaused() private view {
    require(_salePaused, "Sale not paused");
  }

  function pauseSale() public onlyOwner {
    _requireSaleNotPaused();
    _salePaused = true;
    emit SalePaused();
  }

  function unpauseSale() public onlyOwner {
    _requireSalePaused();
    _salePaused = false;
    emit SaleUnpaused();
  }



  // # Minting Helpers

  function _safeMintQuantity(address to, uint quantity) private {
    uint fromTokenId = _totalMintedCount + 1;
    uint toTokenId = _totalMintedCount + quantity + 1;
    _totalMintedCount += quantity;
    for (uint i = fromTokenId; i < toTokenId; i++) {
      _safeMint(to, i);
    }
  }



  // # Sale Mint

  function presaleMint(uint[] calldata sacredDevilTokenIds, address to) external
  {
    uint quantity = sacredDevilTokenIds.length;
    _requireNotSoldOut();
    require( 
      // solhint-disable-next-line not-rely-on-time
      block.timestamp < PUBLIC_SALE_OPEN_TIME,
      "Presale has ended"
    );
    _requireSaleNotPaused();
    _requireValidQuantity(quantity);
    _requireEnoughSupplyRemaining(quantity);
    // Check the caller passed Sacred Devil token IDs that
    // - Caller owns the corresponding Sacred Devil tokens
    // - The Sacred Devil token ID has not been used before
    for (uint i = 0; i < quantity; i++) {
      uint256 sdTokenId = sacredDevilTokenIds[i];
      address ownerOfSDToken = IERC721(DEVILS_CONTRACT_ADDRESS).ownerOf(sdTokenId);
      require(
        ownerOfSDToken == msg.sender,
        string(abi.encodePacked("You do not own LOSD#", Strings.toString(sdTokenId)))
      );
      require(
        claimedDevils[sdTokenId] == false,
        string(abi.encodePacked("Already minted with LOSD#", Strings.toString(sdTokenId)))
      );
      claimedDevils[sdTokenId] = true;
    }
    _saleMintedCount += quantity;
    _safeMintQuantity(to, quantity);
  }

  function publicSaleMint(address to, uint quantity) external payable
  {
    _requireNotSoldOut();
    require(
      // solhint-disable-next-line not-rely-on-time
      block.timestamp >= PUBLIC_SALE_OPEN_TIME,
      "Public sale not open"
    );
    _requireSaleNotPaused();
    _requireValidQuantity(quantity);
    _requireEnoughSupplyRemaining(quantity);

    _saleMintedCount += quantity;
    _payForMintQuantity(quantity);
    _safeMintQuantity(to, quantity);
  }



  // # Reserved Tokens Minting

  function giftAllRemainingReservedTokensToTreasury() external onlyOwner {
    gift(treasury(), RESERVED_SUPPLY - _reservedMintedCount);
  }

  function gift(address to, uint quantity) public onlyOwner {
    require(
      _reservedMintedCount < RESERVED_SUPPLY,
      "Already gifted all reserved tokens"
    );
    require(
      _reservedMintedCount + quantity <= RESERVED_SUPPLY,
      "Not enough reserved supply to gift"
    );
    _reservedMintedCount += quantity;
    _safeMintQuantity(to, quantity);
  }



  // # For receiving payments

  function setTreasury(address payable newTreasury) public onlyOwner {
    require(
      newTreasury != address(0),
      "Setting treasury to 0 address"
    );
    _treasury = newTreasury;
    emit SetTreasury(_treasury, newTreasury);
  }

  function treasury() public view returns (address) {
    return _treasury;
  }

  function _payForMintQuantity(uint quantity) private {
    require(
      _treasury != address(0),
      "Sending payment to treasury with 0 address"
    );
    uint totalPrice = quantity * SALE_PRICE;
    require(
      totalPrice == msg.value,
      "Incorrect amount of ethers"
    );
    // solhint-disable-next-line avoid-low-level-calls
    (bool sendValueSuccess, ) = _treasury.call{value: totalPrice}("");
    require(
      sendValueSuccess,
      "Failed to send ethers to treasury"
    );
  }



  // # OpenSea approval

  function isApprovedForAll(address owner, address operator)
      override virtual
      public view
      returns (bool)
  {
      ProxyRegistry proxyRegistry = ProxyRegistry(OPENSEA_PROXY_REGISTRY_ADDRESS);
      if (address(proxyRegistry.proxies(owner)) == operator) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }
}

// solhint-disable no-empty-blocks
abstract contract OwnableDelegateProxy {}

abstract contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
