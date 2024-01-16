
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";

import "./ERC721Batch.sol";
import "./Delegated.sol";
import "./Royalties.sol";

contract MegaplexPass is ERC721Batch, Delegated, Royalties {
  using Address for address;
  using Strings for uint256;

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  enum SaleState{
    NONE,
    MAINSALE
  }

  MintConfig public config = MintConfig(
    0.25 ether, //ethPrice
     300,       //maxMint
     300,       //maxOrder
     300,       //maxSupply

    SaleState.NONE
  );

  string public tokenURIPrefix;
  string public tokenURISuffix;
  address payable public treasury = payable(0x2Be23419b258c3c82EE0C0E41B4a9C600e8860bd);


  constructor()
    Delegated()
    ERC721B("Megaplex Pass", "MP")
    Royalties( treasury, 1000, 10000 ){
    setDelegate(treasury, true);
  }


  //payable
  function mint( uint16 quantity ) external payable {
    require( quantity > 0, "Must order 1+" );

    MintConfig memory cfg = config;
    require( cfg.saleState == SaleState.MAINSALE,       "Sale is not active" );
    require( quantity <= cfg.maxOrder,                  "Order too big" );

    Owner memory prev = owners[msg.sender];
    require( prev.purchased + quantity <= cfg.maxMint,  "Mint limit reached" );

    uint supply = totalSupply();
    require( supply + quantity <= cfg.maxSupply,        "Mint/Order exceeds supply" );
    require( msg.value == cfg.ethPrice * quantity,      "Ether sent is not correct" );

    unchecked{
      owners[msg.sender] = Owner(
        prev.balance + quantity,
        prev.purchased + quantity
      );

      for(uint256 i; i < quantity; ++i ){
        _mint( msg.sender, supply + i );
      }
    }

    Address.sendValue(treasury, msg.value);
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    unchecked{
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    uint supply = totalSupply();
    require( supply + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );

    unchecked{
      for(uint256 i; i < recipient.length; ++i){
        owners[recipient[i]].balance += quantity[i];

        for(uint256 j; j < quantity[i]; ++j ){
          _mint( recipient[i], supply + j );
        }
      }
    }
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    require( newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require( newConfig.saleState <= type(SaleState).max, "invalid sale state" );

    config = newConfig;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }

  //only owner or treasury
  function setDefaultRoyalty( uint16 feeNumerator, uint16 feeDenominator ) external {
    require(msg.sender == treasury || msg.sender == owner(), "Only the treasury or owner can set royalties");
    _setDefaultRoyalty( treasury, feeNumerator, feeDenominator );
  }

  //only treasure
  function setTreasury( address payable newTreasury ) external {
    require(msg.sender == treasury, "Only the current treasury can set a successor");

    _setDefaultRoyalty( newTreasury, defaultRoyalty.fraction.numerator, defaultRoyalty.fraction.denominator );
    treasury = newTreasury;
  }


  //view: IERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableB, Royalties) returns (bool) {
    return ERC721EnumerableB.supportsInterface(interfaceId)
      || Royalties.supportsInterface(interfaceId);
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) external view returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }
}
