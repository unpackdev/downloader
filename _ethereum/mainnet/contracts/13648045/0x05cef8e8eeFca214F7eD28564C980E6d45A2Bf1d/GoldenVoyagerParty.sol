
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "./Delegated.sol";
import "./ERC721EnumerableB.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";

contract GoldenVoyagerParty is Delegated, ERC721EnumerableB, PaymentSplitter {
  using Strings for uint;

  struct TokenData {
    string name;
    string description;
    string story;
  }

  uint public MAX_ORDER  = 15;
  uint public MAX_SUPPLY = 20; //9000
  uint public PRICE      = 0.04 ether;

  bool public isActive   = false;
  uint public personalizePrice = 0 ether;
  mapping(string => uint) public names;
  mapping(uint => TokenData) public personalized;

  string private _baseTokenURI = 'https://api.goldenvoyagerparty.com/attributes/';
  string private _tokenURISuffix = '';

  address[] private payees = [
    0x8cd08eeDF8F42283252Ea5410c9d80a7A3E094C2,
    0x1C97F77BBC2Aee26e01f21B89e0Ed9c14ac1A7F8,
    0xbb6690b41C167a6Fa421C06C61a87aD8552ed501,
    0x68eed8335C55e5624abE1C3aD213A8A60C89a78a,
    0x8913fF693D140d32402253e8b70894d08C7f39bd,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];

  uint[] private splits = [
    50,
    20,
    10,
     9,
     3,
     8
  ];

  constructor()
    ERC721B("Golden Voyager Party", "GVP", 1 )
    PaymentSplitter( payees, splits ){
  }

  //external
  function burn(uint256 tokenId) external {
    require(_msgSender() == ownerOf(tokenId), "only owner allowed to burn");
    _burn(tokenId);
  }

  function getTokensByOwner(address owner) external view returns(uint256[] memory) {
    return _walletOfOwner(owner);
  }

  function tokenData(uint tokenId) external view returns( string[] memory ){
    require( _exists(tokenId), "GVP: nonexistent token" );

    string[] memory data = new string[]( 3 );
    data[0] = personalized[tokenId].name;
    data[1] = personalized[tokenId].description;
    data[2] = personalized[tokenId].story;
    return data;
  }

  function walletOfOwner(address owner) external view returns(uint256[] memory) {
    return _walletOfOwner( owner );
  }

  //external payable
  fallback() external payable {}

  function mint( uint quantity ) external payable {
    require( isActive,                      "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRICE * quantity, "Ether sent is not correct" );

    uint256 supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i = 0; i < quantity; ++i){
      _safeMint( msg.sender, next(), "" );
    }
  }

  function personalize( uint tokenId, string calldata name, string calldata description, string calldata story ) external payable {
    bool isAuthorized = _msgSender() == ownerOf( tokenId ) || _delegates[ _msgSender() ];
    require( isAuthorized,     "GVP: Not authorized" );
    require( _exists(tokenId), "GVP: nonexistent token" );

    bool isUnsetOrSelf = names[ name ] == 0 || names[ name ] == tokenId;
    require( isUnsetOrSelf,    "GVP: Name in use" );
    if( personalizePrice > 0 )
      require( msg.value >= personalizePrice, "GVP: Not enough ether sent" );

    names[ name ] = tokenId;
    personalized[ tokenId ] = TokenData( name, description, story );
  }

  //onlyDelegates
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    uint256 supply = totalSupply();
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    delete totalQuantity;

    for(uint i = 0; i < recipient.length; ++i){
      for(uint j = 0; j < quantity[i]; ++j){
        _safeMint( recipient[i], next(), "" );
      }
    }
  }

  function setActive(bool isActive_) external onlyDelegates{
    require( isActive != isActive_, "New value matches old" );
    isActive = isActive_;
  }

  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates{
    _baseTokenURI = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  function setMaxOrder(uint maxOrder) external onlyDelegates{
    require( MAX_ORDER != maxOrder, "New value matches old" );
    MAX_ORDER = maxOrder;
  }

  function setPrice(uint price, uint personalizePrice_) external onlyDelegates{
    require( PRICE != price || personalizePrice != personalizePrice_, "New value matches old" );
    PRICE = price;
    personalizePrice = personalizePrice_;
  }


  //onlyOwner
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require( MAX_SUPPLY != maxSupply, "New value matches old" );
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }


  //public
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
  }

  //private
  function _walletOfOwner(address owner) private view returns(uint256[] memory) {
    uint256 balance = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](balance);
    for(uint256 i; i < balance; i++){
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }
}
